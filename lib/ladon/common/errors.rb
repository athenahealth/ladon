module Ladon
  # Error raised as default implementation of "abstract" methods, to signal missing method definitions.
  class MissingImplementationError < StandardError
  end

  # Error used to signal that a block was required but not given.
  class BlockRequiredError < StandardError
  end

  # Error raised when a +halting_assert+ fails.
  class AssertionFailedError < RuntimeError
    # Create an instance with the given message.
    #
    # @param [String] msg The message to display as part of the Error.
    def initialize(msg)
      super("Assertion failed: #{msg}")
    end
  end
end
