module Ladon
  module Modeler
    # Facilitates configuration of +Ladon::Modeler::Graph+ instances.
    #
    # @attr_reader [Ladon::Flags] flags The flags to use to configure a Ladon model.
    class Config
      attr_reader :flags

      # Create a new Modeler Config instance.
      #
      # @param [Ladon::Flags|Hash] flags The Flags instance to use, or a Hash to use to build a Flags instance.
      def initialize(flags: nil)
        @flags = flags.is_a?(Ladon::Flags) ? flags : Ladon::Flags.new(in_hash: flags)
      end
    end
  end
end
