require 'ladon/automator/api/assertions'
require 'ladon/automator/data/config'
require 'ladon/automator/data/result'
require 'ladon/automator/logging/logger'
require 'ladon/automator/timing/timer'

module Ladon
  module Automator
    # Base class for Ladon automation. This class is exposed to encapsulate the
    # aspects of Automation not pertaining directly to operating through a model.
    #
    # @abstract
    #
    # @attr_reader [Ladon::Automator::Config] config The config object used to instantiate this Automation.
    # @attr_reader [Ladon::Automator::Result] result The current result data for this Automation.
    # @attr_reader [Fixnum] phase The current phase number, as index into return value of +all_phases+
    # @attr_reader [Ladon::Flags] flags The flags given to this automation at instantiation.
    class Automation
      include API::Assertions # load assertions API

      @is_abstract = true

      attr_reader :config, :result, :phase, :flags

      SETUP_PHASE = :setup # name for the setup phase
      EXECUTE_PHASE = :execute # name for the execute phase
      TEARDOWN_PHASE = :teardown # name for the teardown phase

      # Create an instance based on the +config+ provided.
      #
      # @raise [ArgumentError] if provided config is not a Ladon::Automator::Config instance.
      #
      # @param [Ladon::Automator::Config] config The configuration object for this automation.
      def initialize(config)
        raise ArgumentError, 'Ladon::Automator::Config required!' unless config.is_a?(Ladon::Automator::Config)
        @config = config
        @flags = config.flags
        @result = Result.new(config)
        @logger = @result.logger
        @timer = @result.timer
        @phase = 0
      end

      # Convenience method to spawn an instance of this class without having to manually build a config.
      #
      # @param [Object] id The id to associate with the spawned Automation.
      # @param [Ladon::Automator::Logging:Level] log_level The log level to configure the Automation at.
      # @param [Ladon::Flags|Hash] flags The flags to pass to the spawned automation.
      def self.spawn(id: SecureRandom.uuid, log_level: nil, flags: nil)
        self.new(Ladon::Automator::Config.new(id: id, log_level: log_level, flags: flags))
      end

      # Identifies the phases from +all_phases+ that *must* be defined for automations of this type.
      #
      # *Note:* this phase plan is just a decent foundational plan; subclasses are free to
      # define their own custom phase plans with arbitrary phase names.
      #
      # @return [Array<Symbol>] Array of Symbols identifying methods that must be defined to facilitate required phases.
      def self.required_phases
        [EXECUTE_PHASE]
      end

      # Identifies the phases involved in this automation.
      #
      # *Note:* this phase plan is just a decent foundational plan; subclasses are free to
      # define their own custom phase plans with arbitrary phase names.
      #
      # @return [Array<Symbol>] Array of Symbols identifying methods that may be defined to facilitate expected phases.
      def self.all_phases
        [SETUP_PHASE, EXECUTE_PHASE, TEARDOWN_PHASE]
      end

      # Declares the class to be abstract. Ladon utilities will not attempt to execute Automations of any class that
      # returns true for this method.
      def self.abstract
        @is_abstract = true
      end

      # Ladon utilities will not attempt to execute Automations of any class that returns true for this method.
      # If false, the subclass is intended as a concrete, runnable Automation implementation.
      # Return false by default unless the subclass calls `.abstract` in the class definition.
      #
      # @return [Boolean] True if this class is abstract, false if not (e.g., is executable.)
      def self.abstract?
        !@is_abstract.nil? && @is_abstract == true
      end

      # Run the automation, from the next phase to be executed through the phase at the index specified.
      # If no +to_index+ is specified or idiomatically invalid, will run through all of the defined phases
      # that have not yet been executed in the phase plan (see: +all_phases+).
      #
      # @param [Fixnum] to_index Phase number (zero indexed) to run through.
      # @return [Ladon::Automator::Result] The result object for this Automation.
      def run(to_index: nil)
        self.class.required_phases.each do |phase|
          raise StandardError, "'#{phase}' not implemented!" unless respond_to?(phase)
        end

        all_phases = self.class.all_phases
        to_index = all_phases.size unless to_index.is_a?(Integer) && to_index.between?(@phase, all_phases.size)
        all_phases[@phase..to_index].each { |phase| do_phase(phase) }

        @result
      end

      # Given an arbitrary code block, this method will execute that block in a rescue construct.
      # Should be used to ensure that the block does not cause the entire execution to die.
      #
      # @raise [BlockRequiredError] if no block given.
      #
      # @param [String] activity_name Description of the behavior taking place in the block.
      def sandbox(activity_name)
        raise BlockRequiredError, 'No block given!' unless block_given?

        begin
          yield
        rescue => ex
          on_error(ex, activity_name)
        end
      end

      # Return a string to indicate why the current automation is skipping the given phase.
      # Return +nil+ to indicate that the phase should not be skipped.
      #
      # @param [Symbol] phase Phase name to determine the current reason to skip (or lack thereof.)
      # @return [String] Description of reason why +phase+ will be skipped; nil if it should not be skipped.
      def skip_reason(phase)
        "No #{phase} method detected!" unless respond_to?(phase)
      end

      private

      # Run a phase of the Automation script, auto-timing the duraction of its execution.
      # The phase will be sandboxed such that an unrescued error during the phase will not crash the entire execution.
      #
      # @param [Symbol] phase Name of phase to execute.
      def do_phase(phase)
        @phase += 1
        skip = skip_reason(phase)
        if skip
          @logger.warn("#{phase} skipped: '#{skip}'")
          return
        end

        @timer.for(phase) do
          @logger.info("Starting #{phase}")
          sandbox(phase) do # mark Automation a failure if a phase fails
            self.send(phase)
            @logger.info("#{phase} completed normally")
          end
        end
      end

      # Behavior to exhibit when a test run phase has an error that is not rescued by the test script's implementation.
      # Marks the Automation as +errored+ and logs the error information.
      #
      # @param [Error] err The error to handle.
      # @param [Symbol] phase The phase during which the +err+ occurred.
      def on_error(err, phase)
        @result.error
        @logger.error(error_to_array(err, description: "#{err.class} in #{phase}: #{err}"))
      end

      # Takes an Error instance and converts it to an array of message lines.
      #
      # @param [Error] err The error to handle.
      # @param [String] description Optional description string to prepend to backtrace.
      #
      # @return [Array<String>] An Array of strings containing error information and backtrace.
      def error_to_array(err, description: nil)
        msg_lines = err.backtrace
        msg_lines.unshift(description) unless description.nil? || description.empty?
        msg_lines
      end
    end
  end
end
