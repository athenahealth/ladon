module Ladon
  module Automator
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
          raise ArgumentError, 'Invalid log level specified!' unless Level.valid?(level)
          @entries = []
          @level = level
          @enabled_levels = Level.enabled_for(level)
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

        # Create a hash-formatted version of logger
        # @return [Hash] value containing logger attributes in a neat format
        def to_h
          log_hash = {}
          @entries.each { |entry| log_hash[entry.time] = entry.to_h }
          log_hash
        end

        # Create a string-formatted version of logger
        # @return [String] printable string containing logger attributes in a neat format
        def to_s
          entries.map( &:to_s ).join("\n")
        end
      end

      # Represents a single item in a Logger's record.
      # The log message are represented as an array of lines
      #
      # @attr_reader [Array<String>] msg_lines The text lines of the message contained in this entry.
      #   This is retained as an Array so that it can be serialized as such and result consumers
      #   can format lines however they want (rather than receiving one big String.)
      # @attr_reader [Level] level The log level this entry was made at.
      # @attr_reader [Time] time The time this log entry was recorded at.
      class LogEntry
        attr_reader :msg_lines, :level, :time

        # Create a new LogEntry.
        #
        # @raise [ArgumentError] If +msg_lines+ is not an array or +level+ is invalid.
        #
        # @param [Array<String>] msg_lines The array of strings that make up the lines of this log entry text.
        # @param [Level] level The logging level to associate with this entry.
        def initialize(msg_lines, level)
          raise ArgumentError, 'LogEntry message must be an array!' unless msg_lines.is_a?(Array)
          raise ArgumentError, 'The level must be one defined in Level::ALL' unless Level::ALL.include?(level)
          @msg_lines = msg_lines
          @level = level
          @time = Time.now.utc
        end

        # Create a string-formatted version of log entry
        # @return [String] printable string containing log entry attributes in a neat format
        def to_s
          str = "#{@level} at #{@time.strftime('%T')}\n"
          str << @msg_lines.map { |msg_line| "\t#{msg_line}" }.join("\n")
        end

        # Create a hash-formatted version of log entry
        # @return [Hash] value containing log entry attributes in a neat format
        def to_h
          { level: @level,
            time: @time,
            msg_lines: @msg_lines }
        end
      end
    end
  end
end
