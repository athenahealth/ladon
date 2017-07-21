module Ladon
  module Automator
    # Represents metadata about Automation phases.
    class Phase
      attr_reader :name, :required, :validator
      alias required? required

      # Create a new Phase instance.
      #
      # @param [String|Symbol] name Name of the phase -- also the name of the method to call to run this phase.
      # @param [Boolean] required Indicates whether or not this phase is required.
      # @param [Proc] validator A block that should take a single positional argument (an automation) and return
      #   true if the automation given as an argument can run the phase this object describes.
      def initialize(name, required: false, validator: nil)
        @name = name.to_sym
        @required = required
        @validator = validator
      end

      # Determine if the given +automation+ is currently capable of executing this phase.
      #
      # @param [Ladon::Automator::Automation] automation The automation to validate against.
      # @return [Boolean] True if the automation can run the phase this object describes, false otherwise.
      def valid_for?(automation)
        return true unless @validator.is_a?(Proc)
        return @validator.call(automation)
      end
    end
  end
end
