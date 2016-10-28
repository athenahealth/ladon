module Ladon
  module Modeler
    class State
      include Ladon::HasContexts

      def initialize(contexts)
        contexts = contexts
      end

      # Class-level method defining the transitions that are available from a given state type.
      def self.transitions
        raise MissingImplementationError, 'transitions'
      end

      def in_context_of(name, &block)
        raise StandardError, 'Required block!' unless block_given?

        # execute the block, giving it the context with the given name
        # equates to a no-op if no context exists with the given name.
        block.call(contexts[name].context_obj) if contexts.key?(name)
      end
    end
  end
end
