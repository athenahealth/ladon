# frozen_string_literal: true

module Ladon
  module Logging
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
        {
          level: @level,
          time: @time,
          msg_lines: @msg_lines
        }
      end
    end
  end
end
