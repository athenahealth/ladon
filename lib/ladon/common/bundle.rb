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
  end
end
