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

        # Create a hash-formatted version of timer
        # @return [Hash] value containing timer attributes in a neat format
        def to_h
          timings = {}
          @entries.each do |entry|
            time_details = { name: entry.name,
                             end: entry.end_time,
                             duration: entry.duration }
            timings[entry.start_time] = time_details
          end
          timings
        end

        # Create a string-formatted version of timer
        # @return [String] printable string containing timer attributes in a neat format
        def to_s
          max_len = _max_len
          str = _to_s_header
          entries.each do |entry|
            time_name = entry.name
            time_duration = entry.duration.round(3)
            str << "  #{time_name}#{_add_buffer(max_len, time_name)}"\
                   "   #{entry.start_time.strftime('%T')}   #{entry.end_time.strftime('%T')}  "\
                   "   #{_add_buffer(7, time_duration)}#{time_duration}\n"
          end
          str
        end

        private

      # Provide a string containing only spaces (used for formatting strings)
      #
      # @param [Integer] len The maximum length of the string to generate
      # @param [Object] offset The amount to shorten the returned string
      # @return [String] string containing only spaces of length +len+ - +offset+.length
      #   or the empty string if +offset+.length > +len+
        def _add_buffer(len, offset = '')
          ' ' * [len - offset.to_s.length, 0].max
        end

        # Determines the maximum length of name from existing entries
        # @return [Integer] the maximum length of an existing entry name
        def _max_len
          max_len = 0
          @entries.each { |e| max_len = [max_len, e.name.length].max }
          max_len
        end

        # Create a header string
        # @return [String] A formatted header
        def _to_s_header
          buffer = _max_len + 1
          "\nTimings: \n"\
          "  Name#{_add_buffer(buffer)} Start#{_add_buffer(5)}   End    Duration\n"\
          "  ----#{_add_buffer(buffer)} -----#{_add_buffer(5)} -----    --------\n"
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

        # Get the duration of the time entry in minutes.
        # @return [Float] The difference in minutes between start_time and end_time
        #   Equals -1.0 if either value is missing
        def duration
          return -1.0 if @start_time.nil? || @end_time.nil?
          (@end_time - @start_time) / 60.0
        end
      end
    end
  end
end
