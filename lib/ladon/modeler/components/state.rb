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
    end
  end
end
