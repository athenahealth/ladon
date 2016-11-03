module Ladon
  module Modeler
    class Config
      attr_reader :flags

      # Create a new Modeler Config instance.
      def initialize(flags: nil)
        @flags = flags.is_a?(Ladon::Flags) ? flags : Ladon::Flags.new(in_hash: flags)
      end
    end
  end
end
