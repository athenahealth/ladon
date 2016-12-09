require 'securerandom'

module Ladon
  module Automator
    # Facilitates configuration of +Ladon::Modeler::Graph+ instances.
    #
    # @attr_reader [Object] id The id associated with this config.
    # @attr_reader [Ladon::Automator::Logging::Level] log_level Log level to use for the Automation's Logger instance.
    # @attr_reader [Ladon::Flags] flags The flags to use to configure a Ladon model.
    class Config
      attr_reader :id, :log_level, :flags

      # Create a new Automator Config instance.
      #
      # @param [Object] id Some identifier used to track the Automation instance.
      # @param [Ladon::Automator::Logging::Level] log_level The log level to use for the Automation's Logger instance.
      # @param [Ladon::Flags|Hash] flags The Flags instance to use, or a Hash to use to build a Flags instance.
      def initialize(id: SecureRandom.uuid, log_level: nil, flags: nil)
        @id = id
        @flags = flags.is_a?(Ladon::Flags) ? flags : Ladon::Flags.new(in_hash: flags)
        @log_level = Automator::Logging::Level::ALL.include?(log_level) ? log_level : Automator::Logging::Level::ERROR
      end

      # Create a hash-formatted version of config
      # @return [Hash] value containing config attributes in a neat format
      def to_h
        { id: @id, flags: @flags.flags }
      end

      # Create a string-formatted version of config
      # @return [String] printable string containing config attributes in a neat format
      def to_s
        str = "\nID: #{@id}\n\nFlags: \n"
        buffer = _max_len
        @flags.flags.each { |flag, value| str << "  #{flag}  #{_buffer(buffer, flag)}=>  #{value}\n" }
        str
      end

      private

      # Provide a string containing only spaces (used for formatting strings)
      #
      # @param [Integer] len The maximum length of the string to generate
      # @param [Object] offset The amount to shorten the returned string
      # @return [String] string containing only spaces of length +len+ - +offset+.length
      #   or the empty string if +offset+.length > +len+
      def _buffer(len, offset = '')
        ' ' * [len - offset.to_s.length, 0].max
      end

      # Determines the maximum length of name from existing flags
      # @return [Integer] the maximum length of an existing flag name
      def _max_len
        max_len = 0
        @flags.flags.each { |f, _| max_len = [max_len, f.length].max }
        max_len
      end
    end
  end
end
