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
      abstract

      attr_accessor :model

      BUILD_MODEL_PHASE = :build_model # name of the phase used to construct the model instance
      VERIFY_MODEL_PHASE = :verify_model # name of the phase used to verify validity of the model instance

      def self.phases
        super + [
          Phase.new(:build_model, required: true),
          Phase.new(:verify_model, required: true)
        ]
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
