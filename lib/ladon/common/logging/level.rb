module Ladon
  # Defines the Logging interface for Automation instances.
  module Logging
    # Defines the valid Logging Levels for Logger instances.
    module Level
      DEBUG = :DEBUG # Debug logging level (most verbose)
      INFO = :INFO # Info logging level
      WARN = :WARN # Warn logging level
      ERROR = :ERROR # Error logging level
      FATAL = :FATAL # Fatal logging level (least verbose)

      # Setting log level to one of these activates all levels to the right of it in this list.
      ALL = [DEBUG, INFO, WARN, ERROR, FATAL].freeze

      # Determine if +thing+ is a valid logging level.
      #
      # @param [Object] thing The thing we want to confirm/refute as a valid logging level.
      # @return [Boolean] True if +thing+ is a valid logging level, false otherwise.
      def self.valid?(thing)
        ALL.include?(thing)
      end

      # Get the list of levels that are enabled for the given +level+ argument.
      #
      # *Note:* If the argument is not a valid logging level, will return an empty array.
      #
      # @param [Object] level The logging level for which we need to find the enabled level set.
      # @return [Array<Ladon::Automator::Logging::Level>] Array of enabled logging levels for
      #   a Logger configured at the given +level+.
      def self.enabled_for(level)
        index_of = ALL.index(level)
        return [] if index_of.nil?
        return ALL[index_of..-1]
      end
    end
  end
end
