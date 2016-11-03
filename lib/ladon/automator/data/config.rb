require 'securerandom'

module Ladon
  module Automator
    class Config
      attr_reader :id, :log_level, :flags

      # Create a new Automator Config instance.
      def initialize(id: SecureRandom.uuid, log_level: nil, flags: nil)
        @id = id
        @flags = flags.is_a?(Ladon::Flags) ? flags : Ladon::Flags.new
        @log_level = Automator::Logging::Level::ALL.include?(log_level) ? log_level : Automator::Logging::Level::ERROR
      end
    end
  end
end
