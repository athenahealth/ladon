module Ladon
  module Modeler
    # Error raised when trying to call +Graph#merge+ with an incompatible source Graph
    class InvalidMergeError < StandardError
    end

    class InvalidStateTypeError < StandardError
      def initialize(given_type)
        super(given_type.to_s)
      end
    end
  end
end