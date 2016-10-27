module Ladon
  module Automator
    module Logging
      module Level
        DEBUG = :DEBUG
        INFO = :INFO
        WARN = :WARN
        ERROR = :ERROR
        FATAL = :FATAL

        # Setting log level to one of these activates all levels to the right of it in this list.
        ALL = [DEBUG, INFO, WARN, ERROR, FATAL].freeze

        # Determine if +thing+ is a valid logging level.
        def self.valid?(thing)
          ALL.include?(thing)
        end

        # Get the list of levels that are enabled for the given +level+ argument.
        # If the argument is not a valid logging level, will return an empty array.
        def self.enabled_for(level)
          index_of = ALL.index(level)
          return [] if index_of.nil?
          return ALL[index_of..-1]
        end
      end

      # Can log messages at specified levels to create a text record of activity.
      class Logger
        attr_reader :entries, :level, :enabled_levels

        # Create a LadonLogger, configured to store log messages at or above the given log level.
        #
        # * Arguments:
        #   - +log_level+:: Lowest level from LOG_LEVELS that this logger will retain.
        def initialize(level: Level::ERROR)
          raise StandardError, 'Invalid log level specified!' unless Level.valid?(level)
          @entries = []
          @level = level
          @enabled_levels = Level.enabled_for(level)
        end

        # Attempt to log a message at a given +level+.
        # If +level+ is below the logger's set level, the call will equate to a no-op.
        #
        # * Arguments:
        #   - +msg+:: The message to be logged.
        #   - +level+:: Level to log +msg+ at. Must be a symbol from +LOG_LEVELS+.
        def log(msg, level: Level::WARN)
          return unless @enabled_levels.include?(level)

          msg = [msg.to_s] unless msg.is_a?(Array)
          new_entry = LogEntry.new(msg, level)
          @entries << new_entry
          return new_entry
        end

        # Shortcut to create a debug log entry.
        def debug(msg)
          log(msg, level: Level::DEBUG)
        end

        # Shortcut to create an info log entry.
        def info(msg)
          log(msg, level: Level::INFO)
        end

        # Shortcut to create a warn log entry.
        def warn(msg)
          log(msg, level: Level::WARN)
        end

        # Shortcut to create an error log entry.
        def error(msg)
          log(msg, level: Level::ERROR)
        end

        # Shortcut to create a fatal log entry.
        def fatal(msg)
          log(msg, level: Level::FATAL)
        end
      end

      # Represents a single item in a Logger's record.
      # The log message are represented as an array of lines
      class LogEntry
        attr_reader :msg_lines, :level, :time

        # Create a new LogEntry.
        def initialize(msg_lines, level)
          raise StandardError, 'LogEntry message must be an array!' unless msg_lines.is_a?(Array)
          raise StandardError, 'The level must be one defined in Level::ALL' unless Level::ALL.include?(level)
          @msg_lines = msg_lines
          @level = level
          @time = Time.now.utc
        end
      end
    end
  end
end

