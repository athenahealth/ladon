module Ladon
  module Modeler
    # Error raised when trying to call +FiniteStateMachine::merge+ with an incompatible source FSM
    class InvalidMergeError < StandardError
    end

    class InvalidStateTypeError < StandardError
      def initialize(reqd_type, given_type)
        super("Expected: #{reqd_type}; Given: #{given_type}")
      end
    end
  end
end