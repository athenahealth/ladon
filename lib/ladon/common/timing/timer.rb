# frozen_string_literal: true

module Ladon
  # Defines the execution Timing interface for Automation instances.
  module Timing
    # Can Time how long it takes for a given code block to execute.
    #
    # @attr_reader [Array<TimeEntry>] entries The TimeEntry instances recorded by this Timer.
    class Timer
      attr_reader :entries

      # Make a new Timer instance.
      def initialize
        @entries = []
      end

      # API for measuring the time that elapses while executing an arbitrary block of behavior.
      #
      # @raise [StandardError] if no block is given.
      # @raise [StandardError] if entry name is not provided.
      #
      # @param [String] entry_name Name to associate with the timing data.
      # @return [TimeEntry] The new entry that was created.
      def for(entry_name)
        raise StandardError, 'No block given!' unless block_given?

        timer = TimeEntry.new(entry_name)
        @entries << timer

        timer.start
        yield
        timer.end
        timer
      end

      # Get the total run time (sum of all entry durations).
      # @return [Float] The sum of the entry durations in minutes.
      def total_time
        @entries.reduce(0) { |sum, entry| sum + entry.duration }
      end

      # Create a hash-formatted version of timer
      # @return [Hash] value containing timer attributes in a neat format
      def to_h
        @entries.each_with_object({}) { |entry, timings| timings[entry.name] = entry.to_h }
      end

      # Create a string-formatted version of timer
      # @return [String] printable string containing timer attributes in a neat format
      def to_s
        entries.map(&:to_s).join("\n")
      end
    end
  end
end
