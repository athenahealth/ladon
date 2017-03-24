require 'securerandom'

module Ladon
  # Facilitates configuration of Ladon models and automations.
  #
  # @attr_reader [Object] id The id associated with this config.
  # @attr_reader [Ladon::Logging::Level] log_level Log level to use for the
  #   object's Logger instance.
  # @attr_reader [Ladon::Flags] flags The flags to use to configure a Ladon
  #   model.
  class Config
    attr_reader :id, :log_level, :flags, :class_name

    # Create a new Config instance.
    #
    # @param [String] class_name Name of the automation.
    # @param [Object] id Some identifier used to track the object instance.
    # @param [Ladon::Logging::Level] log_level The log level to use for the
    #   object's Logger instance.
    # @param [Hash] flags The Hash containing flag values.
    def initialize(
      class_name: nil,
      flags: nil,
      id: SecureRandom.uuid,
      log_level: nil
    )
      @id = id
      @flags = flags.is_a?(Hash) ? flags : {}
      @log_level = Logging::Level::ALL.include?(log_level) ? log_level : Logging::Level::ERROR
      @class_name = class_name
    end

    # Create a hash-formatted version of config
    # @return [Hash] value containing config attributes in a neat format
    def to_h
      {
        id: @id,
        log_level: @log_level.to_s,
        flags: @flags,
        class_name: @class_name
      }
    end

    # Create a string-formatted version of config
    # @return [String] printable string containing config attributes in a neat format
    def to_s
      [
        "Id: #{@id}",
        "Class Name: #{@class_name}",
        "Log Level: #{@log_level}",
        'Flags:',
        @flags.map { |flag, value| "#{flag}  => #{value}" }.join("\n")
      ].join("\n")
    end
  end
end
