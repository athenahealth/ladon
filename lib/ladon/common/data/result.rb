require 'json'

module Ladon
  # Represents the accumulated outcome data for a Ladon object.
  # Includes success/failure info, as well as any timing, log, and data_log information.
  #
  # @attr_reader [Ladon::Config] config The config used to instantiate the Ladon object.
  # @attr_reader [Ladon::Logging::Logger] logger The logger and its log record for the Ladon object.
  # @attr_reader [Ladon::Timing::Timer] timer The execution timer and time log for the Ladon object.
  # @attr_reader [Hash<Object, Object>] data_log The arbitrary key:value data log associated with the Ladon object.
  # @attr_reader [Symbol] status The symbol representing success/failure/error result.
  class Result
    attr_reader :logger, :timer, :status, :data_log, :config

    SUCCESS_FLAG = :SUCCESS # Indicates that the Automation completed normally
    FAILURE_FLAG = :FAILURE # Indicates that the Automation failed as the result of some assertion
    ERROR_FLAG = :ERROR # Indicates that the Automation failed due to some unexpected error

    # Create a new Result instance.
    #
    # @param [Ladon::Config] config The config that was given to the object this result belongs to.
    # @param [Ladon::Logging::Logger] logger The logger that should be included in the results.
    # @param [Ladon::Timing::Timer] timer The timer that should be included in the results.
    def initialize(config:, logger: nil, timer: nil)
      @status = SUCCESS_FLAG # every Result is a success until something bad happens
      @config = config
      @timer = timer
      @logger = logger
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
      {
        status: @status,
        config: @config.to_h,
        timings: @timer.to_h,
        log: @logger.to_h,
        data_log: @data_log
      }
    end

    # Create a string-formatted version of result
    # @return [String] printable string containing result attributes in a neat format
    def to_s
      [
        "STATUS: #{@status}\n",
        'CONFIGURATIONS:',
        "#{@config}\n",
        'TIMINGS:',
        "#{@timer}\n",
        'LOG MESSAGES:',
        "#{@logger}\n",
        'DATA LOG:',
        "#{@data_log}\n"
      ].join("\n")
    end

    # Create a JSON-formatted version of result
    #
    # @return [String] containing result attributes in a JSON format
    def to_json
      JSON.pretty_generate(to_h)
    end
  end
end
