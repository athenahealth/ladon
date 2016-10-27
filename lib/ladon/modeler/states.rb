module Ladon
  module Modeler
    class State
      # Class-level method defining the transitions that are available from a given state type.
      def self.transitions
        raise StandardError, 'The transitions method is not implemented!'
      end
    end
  end
end
