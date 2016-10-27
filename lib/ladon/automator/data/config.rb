require 'securerandom'

module Ladon
  module Automator
    class Config
      attr_accessor :id, :log_level

      # Create a new Automator Config instance.
      def initialize(id: SecureRandom.uuid, log_level: :ERROR)
        @id = id
        @log_level = log_level
      end
    end
  end
end