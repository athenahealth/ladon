module Ladon
  module Automator
    class Result
      attr_reader :logger, :timer, :status, :data_log, :config

      # Indicates that the Result's AutomationRun completed normally
      SUCCESS_FLAG = :SUCCESS
      # Indicates that the Result's AutomationRun failed as the result of some assertion
      FAILURE_FLAG = :FAILURE
      # Indicates that the Result's AutomationRun failed due to some unexpected error
      ERROR_FLAG = :ERROR

      # Create a new Automator Result instance.
      def initialize(config)
        @config = config
        @id = config.id
        @status = SUCCESS_FLAG # every Result is a success until something bad happens
        @logger = Ladon::Automator::Logging::Logger.new(level: config.log_level)
        @timer = Ladon::Automator::Timing::Timer.new
        @data_log = {}
      end

      # Record an arbitrary key:value pair.
      def record_data(key, value = nil)
        raise StandardError, 'Key is required!' if key.nil? || key.empty?
        @data_log[key] = value
      end

      # Mark this run as having encountered a failure.
      def failure
        @status = FAILURE_FLAG if @status == SUCCESS_FLAG
      end

      # Mark this Result as having encountered an error.
      def error
        @status = ERROR_FLAG if @status == SUCCESS_FLAG
      end

      def success?
        @status == SUCCESS_FLAG
      end

      def failure?
        @status == FAILURE_FLAG
      end

      def error?
        @status == ERROR_FLAG
      end
    end
  end
end