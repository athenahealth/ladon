module Ladon
  module Modeler

    # The base type for representing Nodes/States in Ladon graph models.
    #
    # @abstract
    class State

      # Class-level method defining the transitions that are available from a given state type.
      #
      # @abstract
      # @return [Array<Ladon::Modeler::Transition>] List of Transition instances that
      #   are valid from instances of this State type.
      def self.transitions
        raise MissingImplementationError, 'self.transitions'
      end
    end
  end
end
