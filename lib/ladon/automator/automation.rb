module Ladon
  module Automator
    # Base class for Ladon automation. This class is exposed to encapsulate the
    # aspects of Automation not pertaining directly to operating through a model.
    #
    # @abstract
    class Automation < Bundle
      @is_abstract = true

      # Identifies the phases involved in this automation.
      # @return [Array<Phase>] Ordered array defining the Phases of this class of automation.
      def self.phases
        []
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

      # Run the automation, executing each phase defined for the automation class in order.
      # @return [Ladon::Result] The result object for this Automation.
      def run
        raise MissingImplementationError, 'Cannot run an abstract automation!' if self.class.abstract?
        sandbox('Run') { self.class.phases.each { |phase| process_phase(phase) } }
        @result
      end

      private

      # Run a phase of the Automation script, auto-timing the duraction of its execution.
      # The phase will be sandboxed such that an unrescued error during the phase will not crash the entire execution.
      #
      # @param [Phase] phase The phase to execute.
      def process_phase(phase)
        @logger.info("Processing phase: '#{phase.name}'")

        return unless phase_valid?(phase)
        execute_phase(phase)
      end

      # Determines if the given automation validates successfully against the current automation.
      #
      # @param [Phase] phase The phase to execute.
      # @return [Boolean] True if the phase is currently valid for this automation, false otherwise.
      def phase_valid?(phase)
        return true if phase.valid_for?(self)

        @logger.warn("Phase validation failed; phase #{phase.name} skipped!")
        false
      end

      # Determines if the given automation validates successfully against the current automation.
      #
      # @param [Phase] phase The phase to execute.
      # @return [Boolean] True if the phase is currently valid for this automation, false otherwise.
      def phase_skipped?(phase)
        return false if respond_to?(phase.name)

        @logger.log("Phase '#{phase.name}' skipped because it is not defined",
                    level: phase.required? ? Ladon::Logging::Level::ERROR : Ladon::Logging::Level::WARN)
        true
      end

      # @param [Phase] phase The phase to execute.
      def execute_phase(phase)
        if phase_skipped?(phase)
          @result.failure if phase.required?
          return
        end

        @timer.for(phase.name) do
          sandbox(phase.name) do # mark Automation a failure if a phase fails
            self.send(phase.name)
            @logger.info("#{phase.name} completed normally")
          end
        end
      end
    end
  end
end
