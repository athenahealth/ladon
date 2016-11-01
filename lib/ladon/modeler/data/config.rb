require 'securerandom'

module Ladon
  module Modeler
    class Config
      include Ladon::HasContexts
      attr_accessor :id, :start_state, :contexts, :load_strategy

      # Create a new Automator Config instance.
      def initialize(start_state: nil,
                     id: SecureRandom.uuid,
                     contexts: {},
                     load_strategy: Ladon::Modeler::Graph::LoadStrategy::LAZY)
        @id = id
        self.contexts = contexts

        # both start_state AND load_strategy must be defined for these settings to take effect
        @start_state = start_state
        @load_strategy = load_strategy
      end
    end
  end
end
