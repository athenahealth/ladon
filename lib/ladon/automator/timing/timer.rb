module Ladon
  module Automator
    module Timing
      class Timer
        attr_reader :entries

        # Make a new Timer instance.
        def initialize
          @entries = []
        end

        # API for measuring the time that elapses while executing an arbitrary block of behavior.
        #
        # * Arguments:
        #   - +metric_name+:: What name to associate with the metric data in the timing info hash.
        #
        # * Raises:
        #   - StandardError if metric name is not provided, is empty, or is already used.
        def for(metric_name, &block)
          raise StandardError, 'No block given!' unless block_given?

          timer = TimeEntry.new(metric_name)
          @entries << timer

          timer.start
          block.call
          timer.end
        end
      end

      # Represents a single timing performed by a +Timer+ instance.
      class TimeEntry
        attr_reader :name, :start_time, :end_time

        # Create a new Timer.
        #
        # * Arguments:
        #   - +name+:: The name of this Timer.
        def initialize(name)
          raise StandardError, 'No name provided!' if name.nil?
          @name = name.to_s
          @start_time = nil
          @end_time = nil
        end

        # Start the timer, recording the UTC time at which it started.
        def start
          @start_time = Time.now.utc
        end

        # End the timer, recording the UTC time at which it ended.
        def end
          @end_time = Time.now.utc
        end
      end
    end
  end
end
