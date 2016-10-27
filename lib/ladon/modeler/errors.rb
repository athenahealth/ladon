module Ladon
  module Modeler
    # Error raised when trying to call +FiniteStateMachine::merge+ with an incompatible source FSM
    class InvalidMergeError < StandardError
    end
  end
end