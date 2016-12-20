module Ladon
  module Timing
    # Represents a single timing performed by a +Timer+ instance.
    #
    # @attr_reader [String] name The name of this entry.
    # @attr_reader [Time] start_time The time at which this entry began recording.
    # @attr_reader [Time] end_time The time at which this entry finished recording.
    class TimeEntry
      attr_reader :name, :start_time, :end_time

      # Create a new Timer.
      #
      # @param [String] name The name of this timing entry.
      def initialize(name)
        raise StandardError, 'No name provided!' if name.nil?
        @name = name.to_s
        @start_time = nil
        @end_time = nil
      end

      # Start the timer, recording the UTC time at which it started.
      # @return [Time] The UTC time that was noted.
      def start
        @start_time = Time.now.utc
      end

      # End the timer, recording the UTC time at which it ended.
      # @return [Time] The UTC time that was noted.
      def end
        @end_time = Time.now.utc
      end

      # Get the duration of the time entry in minutes.
      # @return [Float] The difference in minutes between start_time and end_time
      #   Equals -1.0 if either value is missing
      def duration
        return -1.0 if @start_time.nil? || @end_time.nil?
        (@end_time - @start_time) / 60.0
      end

      # Create a hash-formatted version of time entry
      # @return [Hash] value containing time entry attributes in a neat format
      def to_h
        {
          name: @name,
          start: @start_time,
          end: @end_time,
          duration: duration
        }
      end

      # Create a string-formatted version of time entry
      # @return [String] printable string containing time entry attributes in a neat format
      def to_s
        [
          @name.to_s,
          " - Time Elapsed:  #{duration.round(3)}",
          " - Started:  #{@start_time.strftime('%T')}",
          " - Ended:  #{@end_time.strftime('%T')}"
        ].join("\n")
      end
    end
  end
end
