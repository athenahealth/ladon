module Ladon
  module Modeler
    # Error raised when trying to call +Graph#merge+ with an incompatible source Graph.
    class InvalidMergeError < StandardError
    end

    # Error raised when trying to load model components that are already loaded.
    class AlreadyLoadedError < StandardError
    end

    # Error raised when trying to call a FSM method without a +current_state+.
    class NoCurrentStateError < StandardError
    end

    # Error raised when a FiniteStateMachine attempts a transition and fails.
    class TransitionFailedError < StandardError
    end

    # Error raised when a +Ladon::Automator::Graph+ is instructed to load a state type that is invalid.
    class InvalidStateTypeError < StandardError
      # Create a new instance of this error.
      #
      # @param [Class] given_type The state type that the +Ladon::Automator::Graph+ was instructed to load.
      def initialize(given_type)
        super(given_type.to_s)
      end
    end
  end
end
