module Ladon
  module Modeler
    class State
      include Ladon::HasContexts

      def initialize(contexts)
        self.contexts = contexts
      end

      # Class-level method defining the transitions that are available from a given state type.
      def self.transitions
        raise MissingImplementationError, 'transitions'
      end
    end
  end
end
