require 'ladon/automator/automation'

module Ladon
  module Automator
    # Class for Automation driven through a Ladon Modeler model.
    #
    # The Automation is used to harness a Ladon model and use it to power
    # automated interaction with the software it models.
    #
    # During this automation, you are able to make assertions, maintain
    # an activity log, and measure the observable behaviors of the software.
    #
    # @abstract
    #
    # @attr_reader [Ladon::Modeler::FiniteStateMachine] model The model instance underlying this automation.
    class ModelAutomation < Automation
      attr_accessor :model

      BUILD_MODEL_PHASE = :build_model # name of the phase used to construct the model instance
      VERIFY_MODEL_PHASE = :verify_model # name of the phase used to verify validity of the model instance

      # Identifies the phases from +all_phases+ that *must* be defined for automations of this type.
      # @return [Array<Symbol>] Array of Symbols identifying methods that must be defined to facilitate required phases.
      def self.required_phases
        [BUILD_MODEL_PHASE, VERIFY_MODEL_PHASE, EXECUTE_PHASE]
      end

      # Identifies the phases involved in this automation.
      # @return [Array<Symbol>] Array of Symbols identifying methods that may be defined to facilitate expected phases.
      def self.all_phases
        [BUILD_MODEL_PHASE, VERIFY_MODEL_PHASE, SETUP_PHASE, EXECUTE_PHASE, TEARDOWN_PHASE]
      end

      # Subclasses _MUST_ override this method. This method should return an instance of
      # +Ladon::Modeler::FiniteStateMachine+ that will power this automation.
      #
      # @abstract
      #
      # @return Nil by default
      def build_model
        self.model = nil # set up the model
      end

      # Verifies that the model created in +build_model+ is actually a FSM instance.
      #
      # @raise [StandardError] If the model is not a FSM.
      def verify_model
        raise StandardError, 'The model must be a Ladon FSM' unless model.is_a?(Ladon::Modeler::FiniteStateMachine)
      end
    end
  end
end