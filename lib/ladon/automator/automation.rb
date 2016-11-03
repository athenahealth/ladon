require 'ladon/automator/api/assertions'
require 'ladon/automator/data/config'
require 'ladon/automator/data/result'
require 'ladon/automator/logging/logger'
require 'ladon/automator/timing/timer'

module Ladon
  module Automator
    # Base class for Ladon automation. This class is exposed to encapsulate the
    # aspects of Automation not pertaining directly to operating through a model.
    class Automation
      include API::Assertions

      attr_reader :config, :result, :phase, :flags

      SETUP_PHASE = :setup
      EXECUTE_PHASE = :execute
      TEARDOWN_PHASE = :teardown

      # Create an instance of AutomationRun based on the +config+ provided.
      def initialize(config)
        raise StandardError, 'Automation requires a Ladon::Automator::Config' unless config.is_a?(Ladon::Automator::Config)
        @config = config
        @flags = config.flags
        @result = Result.new(config)
        @logger = @result.logger
        @timer = @result.timer
        @phase = 0
      end

      # Convenience method to spawn an instance of this class without having to manually build a config.
      def self.spawn(id: SecureRandom.uuid, log_level: nil, flags: nil)
        self.new(Ladon::Automator::Config.new(id: id, log_level: log_level, flags: flags))
      end

      # Identifies the phases from +all_phases+ that *must* be defined for automations of this type.
      def self.required_phases
        [EXECUTE_PHASE]
      end

      # Identifies the phases involved in this automation.
      def self.all_phases
        [SETUP_PHASE, EXECUTE_PHASE, TEARDOWN_PHASE]
      end

      # Subclass implementations should override this method to return false if the subclass is intended as
      # a concrete, runnable Automation implementation.
      #
      # Ladon utilities will not attempt to execute Automations of any class that returns true for this method.
      def self.abstract?
        true
      end

      # Run the automation, from the next phase to be executed through the phase at the index specified.
      # If no +to_index+ is specified, will run through all of the defined phases.
      def run(to_index: nil)
        self.class.required_phases.each do |phase|
          raise StandardError, "'#{phase}' not implemented!" unless respond_to?(phase)
        end

        all_phases = self.class.all_phases
        to_index = all_phases.size unless to_index.is_a?(Fixnum) && to_index.between?(@phase, all_phases.size)
        all_phases[@phase..to_index].each { |phase| do_phase(phase) }

        @result
      end

      # Given an arbitrary code block, this method will execute that block in a rescue construct.
      # Should be used to ensure that the block
      def sandbox(activity_name, &block)
        raise StandardError, 'No block given!' unless block_given?

        begin
          block.call
        rescue => ex
          on_error(ex, activity_name)
        end
      end

      # Return a string to indicate why the current automation is skipping the given phase.
      # Return +nil+ to indicate that the phase should not be skipped.
      def skip_reason(phase)
        "No #{phase} method detected!" unless respond_to?(phase)
      end

      private

      # Run a phase of the Automation script, auto-timing the duraction of its execution.
      # The phase will be sandboxed such that an unrescued error during the phase will not crash the entire execution.
      def do_phase(phase)
        @phase += 1
        skip = skip_reason(phase)
        return @logger.warn("#{phase} skipped: '#{skip}'") if skip

        @timer.for(phase) do
          @logger.info("Starting #{phase}")
          sandbox(phase) do # mark Automation a failure if a phase fails
            self.send(phase)
            @logger.info("#{phase} completed normally")
          end
        end
      end

      # Behavior to exhibit when a test run phase has an error that is not rescued by the test script's implementation.
      #
      # * Arguments:
      #   - +err+:: The error that was not
      #   - +phase+:: String identifying the the phase that errored out.
      #   - +fail_test+:: If true, sets the test run to a FAILURE state.
      def on_error(err, phase)
        @result.error
        # TODO: convert log into record of objects?
        @logger.error(error_to_array(err, description: "#{err.class} in #{phase}: #{err}"))
      end

      # Takes an Error instance and converts it to an array of message lines.
      #
      # * Arguments:
      #   - +msg+:: A message to put at the beginning of the message array
      #   - +err+:: The Error to convert to message lines
      #
      # * Returns:
      #   - An Array of strings containing error information, with index = 0 being the first line of the info.
      def error_to_array(err, description: nil)
        msg_lines = err.backtrace
        msg_lines.unshift(description) unless description.nil? || description.empty?
        msg_lines
      end
    end
  end
end
