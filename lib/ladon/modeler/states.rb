module Ladon
  module Modeler
    class State
      # Class-level method defining the transitions that are available from a given state type.
      def self.transitions
        raise MissingImplementationError, 'self.transitions'
      end
    end
  end
end
