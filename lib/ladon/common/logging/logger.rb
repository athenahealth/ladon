module Ladon
  module Logging
    # Can log messages at specified levels to create a text record of activity.
    #
    # @attr_reader [Array<LogEntry>] entries The log entries retained within this Logger.
    # @attr_reader [Level] level The log level this Logger was configured at.
    # @attr_reader [Array<Level>] enabled_level The log levels this Logger will retain.
    class Logger
      attr_reader :entries, :level, :enabled_levels

      # Create a Logger, configured to store log messages at or above the given log level.
      #
      # @raise [ArgumentError] If +level+ is invalid.
      #
      # @param [Level] level Lowest level from Level::ALL that this logger will retain.
      def initialize(level: Level::ERROR)
        self.level = level
        @entries = []
      end

      # Attempt to log a message at a given +level+.
      # If +level+ is below the logger's set level, the call will equate to a no-op.
      #
      # @param [String] msg The message to be logged.
      # @param [Level] level The logging level to log the message at.
      # @return [LogEntry] The newly created log entry (or nil if this call is at an ignored level.)
      def log(msg, level: Level::WARN)
        return nil unless @enabled_levels.include?(level)

        msg = [msg.to_s] unless msg.is_a?(Array)
        new_entry = LogEntry.new(msg, level)
        @entries << new_entry
        return new_entry
      end

      # Shortcut to create a debug log entry.
      # @param [String] msg The message to log.
      def debug(msg)
        log(msg, level: Level::DEBUG)
      end

      # Shortcut to create an info log entry.
      # @param [String] msg The message to log.
      def info(msg)
        log(msg, level: Level::INFO)
      end

      # Shortcut to create a warn log entry.
      # @param [String] msg The message to log.
      def warn(msg)
        log(msg, level: Level::WARN)
      end

      # Shortcut to create an error log entry.
      # @param [String] msg The message to log.
      def error(msg)
        log(msg, level: Level::ERROR)
      end

      # Shortcut to create a fatal log entry.
      # @param [String] msg The message to log.
      def fatal(msg)
        log(msg, level: Level::FATAL)
      end

      # Set the logger's current level to the specified Logging level.
      # Note: does NOT erase existing entries at any level, regardless of the level specified.
      #
      # @raise [ArgumentError] If +level+ is invalid.
      #
      # @param [Level] level The logging level to log the message at.
      def level=(level)
        raise ArgumentError, 'Invalid log level specified!' unless Level.valid?(level)
        @level = level
        @enabled_levels = Level.enabled_for(level)
      end

      # Create a hash-formatted version of logger
      # @return [Hash] value containing logger attributes in a neat format
      def to_h
        {
          level: @level,
          entries: @entries.map(&:to_h)
        }
      end

      # Create a string-formatted version of logger
      # @return [String] printable string containing logger attributes in a neat format
      def to_s
        str = "Level: #{@level}\n"\
              "Entries:\n"
        str << entries.map(&:to_s).join("\n")
      end
    end
  end
end
