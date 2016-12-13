require 'fileutils'
require 'json'

module Ladon
  module Automator
    # Represents the accumulated outcome data for an Automation.
    # Includes success/failure info, as well as any timing, log, and data_log information.
    #
    # @attr_reader [Ladon::Automator::Config] config The config used to instantiate the automation.
    # @attr_reader [Ladon::Automator::Logging::Logger] logger The logger and its log record for the automation.
    # @attr_reader [Ladon::Automator::Timing::Timer] timer The execution timer and time log for the automation.
    # @attr_reader [Hash<Object, Object>] data_log The arbitrary key:value data log associated with the automation.
    # @attr_reader [Symbol] status The symbol representing success/failure/error result
    class Result
      attr_reader :logger, :timer, :status, :data_log, :config

      SUCCESS_FLAG = :SUCCESS # Indicates that the Automation completed normally
      FAILURE_FLAG = :FAILURE # Indicates that the Automation failed as the result of some assertion
      ERROR_FLAG = :ERROR # Indicates that the Automation failed due to some unexpected error

      # Create a new Automator Result instance.
      #
      # @param [Ladon::Automator::Config] config The config that was given to the Automation this result belongs to.
      def initialize(config)
        @config = config
        @status = SUCCESS_FLAG # every Result is a success until something bad happens
        @logger = Ladon::Automator::Logging::Logger.new(level: config.log_level)
        @timer = Ladon::Automator::Timing::Timer.new
        @data_log = {}
      end

      # Record an arbitrary key:value pair in the +data_log+.
      #
      # @raise [ArgumentError] if key is not provided.
      #
      # @param [Object] key The key to use in the data log.
      # @param [Object] value The value to enter into the data log.
      # @return [Object] The value now contained in the data log at the given +key+.
      def record_data(key, value)
        raise ArgumentError, 'Key is required!' if key.nil?
        @data_log[key] = value
      end

      # Mark this run as having encountered a failure.
      # @return [Boolean] New status value.
      def failure
        @status = FAILURE_FLAG if @status == SUCCESS_FLAG
      end

      # Mark this Result as having encountered an error.
      # @return [Boolean] New status value.
      def error
        @status = ERROR_FLAG if @status == SUCCESS_FLAG
      end

      # Ask if the result is marked as a success.
      # @return [Boolean] True if result is a success; false otherwise.
      def success?
        @status == SUCCESS_FLAG
      end

      # Ask if the result is marked as a failure.
      # @return [Boolean] True if result is a failure; false otherwise.
      def failure?
        @status == FAILURE_FLAG
      end

      # Ask if the result is marked as an error.
      # @return [Boolean] True if result is a error; false otherwise.
      def error?
        @status == ERROR_FLAG
      end

      # Create a hash-formatted version of result
      # @return [Hash] value containing result attributes in a neat format
      def to_h
        { data_log: @data_log,
          log: @logger.to_h,
          timings: @timer.to_h,
          status: @status,
          config: @config.to_h }
      end

      # Create a string-formatted version of result
      # @return [String] printable string containing result attributes in a neat format
      def to_s
        # 1. Status
        rep_str = "Status: #{@status}\n"
        rep_str << "Configurations:\n  #{@config.to_s.gsub(/\n/, "\n  ")}\n"
        # 3. Timings
        rep_str << "Timings:\n  #{@timer.to_s.gsub(/\n/, "\n  ")}\n"
        # 4. Log Messages
        rep_str << "Log Messages:\n  #{@logger.to_s.gsub(/\n/, "\n  ")}\n"
        # 5. Data Log
        rep_str << "Data-Log:\n  #{@data_log}\n"
      end

      # Create a JSON-formatted version of result
      # @return [String] containing result attributes in a JSON format
      def to_json
        return JSON.pretty_generate(to_h)
      end
    end
  end
end
