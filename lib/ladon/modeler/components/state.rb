module Ladon
  module Modeler
    # The base type for representing Nodes/States in Ladon graph models.
    #
    # @abstract
    class State
      # Class-level method defining the transitions that are available from a given state type.
      #
      # @abstract
      #
      # @raise [MissingImplementationError] If not overridden by subclass implementation.
      #
      # @return [Enumerable<Ladon::Modeler::Transition>] List-like object containing Transition
      #   instances that are valid from instances of this State type.
      def self.transitions
        raise MissingImplementationError, 'self.transitions'
      end

      # Method used by State instances to determine whether or not they are currently valid.
      # The +FiniteStateMachine+ leverages this method when making Transitions to confirm that the new state
      # is accurate to the software
      #
      # @abstract
      #
      # @return [Boolean] true by default. Subclasses should redefine to implement custom verification semantics.
      def verify_as_current_state?
        true
      end
    end
  end
end
