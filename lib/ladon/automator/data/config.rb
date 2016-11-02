require 'securerandom'

module Ladon
  module Automator
    class Config
      attr_reader :id, :log_level, :flags

      # Create a new Automator Config instance.
      def initialize(id: SecureRandom.uuid, log_level: :ERROR, flags: nil)
        @id = id
        @log_level = log_level
        @flags = flags.is_a?(Ladon::Flags) ? flags : Ladon::Flags.new
      end
    end
  end
end
