require 'securerandom'

module Ladon
  module Modeler
    class Config
      include Ladon::HasContexts
      attr_accessor :id, :start_state, :contexts, :eager

      # Create a new Automator Config instance.
      def initialize(start_state: nil, id: SecureRandom.uuid, contexts: {}, eager: false)
        @id = id
        @start_state = start_state
        @eager = eager
        self.contexts = contexts
      end
    end
  end
end
