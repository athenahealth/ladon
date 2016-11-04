module Ladon
  module Automator
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
      end

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
      end
    end
  end
end
