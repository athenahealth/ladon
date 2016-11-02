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
        to_index = all_phases.size if to_index.nil? || !to_index.is_a?(Fixnum) || to_index > all_phases.size || to_index < @phase
        all_phases[@phase..to_index].each do |phase|
          do_phase(phase, skip: !respond_to?(phase), skip_msg: "No #{phase} method detected.")
        end

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

      private

      # Run a phase of the Automation script, auto-timing the duraction of its execution.
      # The phase will be sandboxed such that an unrescued error during the phase will not crash the entire execution.
      def do_phase(phase, skip: false, skip_msg: nil)
        @phase += 1
        return @logger.warn("#{phase} skipped: '#{skip_msg}'") if skip

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

    # Class for Automation driven through a Ladon Modeler model.
    #
    # The Automation is used to harness a Ladon model and use it to power
    # automated interaction with the software it models.
    #
    # During this automation, you are able to make assertions, maintain
    # an activity log, and measure the observable behaviors of the software.
    class ModelAutomation < Automation
      BUILD_MODEL_PHASE = :build_model
      VERIFY_MODEL_PHASE = :verify_model
      attr_accessor :model

      # Identifies the phases from +all_phases+ that *must* be defined for automations of this type.
      def self.required_phases
        [BUILD_MODEL_PHASE, VERIFY_MODEL_PHASE, EXECUTE_PHASE]
      end

      # Identifies the phases involved in this automation.
      def self.all_phases
        [BUILD_MODEL_PHASE, VERIFY_MODEL_PHASE, SETUP_PHASE, EXECUTE_PHASE, TEARDOWN_PHASE]
      end

      # Subclasses _MUST_ override this method. This method should return an instance of
      # +Ladon::Modeler::FiniteStateMachine+ that will power this automation.
      #
      # By default, this returns nil.
      def build_model
        self.model = nil # set up the model
      end

      def verify_model
        raise StandardError, 'The model must be a Ladon FSM' unless model.is_a?(Ladon::Modeler::FiniteStateMachine)
      end
    end
  end
end