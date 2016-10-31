require 'securerandom'

module Ladon
  module Automator
    class Config
      include Ladon::HasContexts

      attr_accessor :id, :log_level, :contexts

      # Create a new Automator Config instance.
      def initialize(id: SecureRandom.uuid, log_level: :ERROR, contexts: {})
        @id = id
        @log_level = log_level
        self.contexts = contexts
      end
    end
  end
end
