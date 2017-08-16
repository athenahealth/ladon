module Ladon
  # A "Bundle" is any object which is spawned from a Ladon config,
  # has a Logger and a Timer, and maintains a Result.
  #
  # Because a Bundle has all of these things, every Bundle automatically includes
  # the Ladon Assertions API.
  #
  # @attr_reader [Ladon::Config] config The config object used to instantiate this Automation.
  # @attr_reader [Ladon::Flags] flags The flags given to this automation at instantiation.
  # @attr_reader [Ladon::Result] result The current result data for this Automation.
  class Bundle
    extend Ladon::HasFlags
    include Ladon::Assertions
    attr_reader :config, :flags, :logger, :timer, :result

    # Create an instance based on the +config+ provided.
    #
    # @raise [ArgumentError] if provided config is not a Ladon::Config instance.
    #
    # @param [Ladon::Config] config The configuration object for this automation.
    # @param [Ladon::Logging::Logger] logger The logger to use in this automation.
    # @param [Ladon::Timing::Timer] timer The timer to use in this automation.
    def initialize(config: Ladon::Config.new, timer: nil, logger: nil)
      raise ArgumentError, 'Ladon::Config required!' unless config.is_a?(Ladon::Config)
      @config = config
      @timer = timer.is_a?(Ladon::Timing::Timer) ? timer : Ladon::Timing::Timer.new
      @logger = Ladon::Logging::Logger.new(level: @config.log_level) unless logger.is_a?(Ladon::Logging::Logger)
      @logger.level = @config.log_level

      @result = Ladon::Result.new(config: config, timer: @timer, logger: @logger)
      @flags = config.flags
    end

    # Convenience method to spawn an instance of this class without having to manually build a config.
    #
    # @param [Object] id The id to associate with the spawned Bundle.
    # @param [Ladon::Logging::Level] log_level The log level to configure the Bundle's logger at.
    # @param [Ladon::Flags|Hash] flags The flags to pass to the spawned Bundle.
    # @param [String] class_name Name of the automation.
    # @param [String] path File path to the automation.
    def self.spawn(
      id: SecureRandom.uuid,
      log_level: nil,
      flags: nil,
      class_name: nil,
      path: nil,
      data: nil
    )
      self.new(
        config: Ladon::Config.new(
          flags: flags,
          id: id,
          log_level: log_level,
          class_name: class_name,
          path: path,
          data: data
        )
      )
    end

    # Given an arbitrary code block, this method will execute that block in a rescue construct.
    # Should be used to ensure that the block does not cause the entire execution to die.
    #
    # @raise [BlockRequiredError] if no block given.
    #
    # @param [String] activity_name Description of the behavior taking place in the block.
    def sandbox(activity_name)
      raise BlockRequiredError, 'No block given!' unless block_given?

      begin
        yield
      rescue => ex
        on_error(ex, activity_name)
      end
    end

    private

    # Behavior to exhibit when a test run phase has an error that is not rescued by the test script's implementation.
    # Marks the Automation as +errored+ and logs the error information.
    #
    # @param [Error] err The error to handle.
    # @param [Symbol] phase The phase during which the +err+ occurred.
    def on_error(err, phase)
      @result.error
      @logger.error(error_to_array(err, description: "#{err.class} in #{phase}: #{err}"))
    end

    # Takes an Error instance and converts it to an array of message lines.
    #
    # @param [Error] err The error to handle.
    # @param [String] description Optional description string to prepend to backtrace.
    #
    # @return [Array<String>] An Array of strings containing error information and backtrace.
    def error_to_array(err, description: nil)
      msg_lines = err.backtrace
      msg_lines.unshift(description) unless description.nil? || description.empty?
      msg_lines
    end
  end
end
