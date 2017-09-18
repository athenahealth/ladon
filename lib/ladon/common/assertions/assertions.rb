module Ladon
  # Defines the API for making assertions about the execution behavior of the +Automation+.
  module Assertions
    # Make an assertion by running the given block in a sandbox. If the block raises, the assertion
    # is considered a failure. If the block is not specified, actual and expected values will be
    # compared. The arguments actual & expected can be used for debugging purposes on block evaluation.
    #
    # *Note:* if the block executes without error, it *must* return *true* to be considered
    # a success. This is an explicit design decision: because it is so easy to incidentally return
    # a value, we force asserters to return *true* as the *only* way to indicate "success" of assertion.
    # This should decrease the likelihood of false positive assertions due to incidental return values.
    #
    # @raise [ArgumentError] If no block is given or expected values have not been specified
    # @raise [AssertionFailedError] If the assertion raises or returns something other than true, when halting
    # is set
    #
    # @param [String] msg The message to use in the log/error if the assertion fails.
    # @param [Boolean] halting If true, halt the Automation's execution of its current phase on assertion failure.
    # @param [Integer/String/Array/Hash] expected, represents the value we are expecting as a part of assertion
    # @param [Integer/String/Array/Hash] actual, represents the actual value identified in test execution
    #
    # @return [Boolean] True if the assertion succeeds, false otherwise.
    def assert(msg, halting: false, expected: nil, actual: nil)
      # Verify the input arguments and raise exeptions if needed. Actual values might be nil based on scenario
      # executed but expected values have to be specified for comparison.
      raise ArgumentError, 'No assertion block or actual/expected values passed!' unless block_given? || !expected.nil?
      # Evaluate the assert, if input assert block is available execute the same.
      # When block is not specified compare the actual/expected values
      begin
        passed = block_given? ? yield : (actual == expected)
      rescue StandardError => ex
        passed = false
        @logger.error(error_to_array(ex, description: "Error during attempt to evaluate assertion block: #{ex}"))
      end
      # Log to output file based on the assertion logic status
      if passed == true # True vs truthy; see *note* in method doc
        @logger.info("Assertion passed: '#{msg}'")
      else
        on_failed_assertion(msg, halting, expected, actual)
      end
      # Return success/failure of assert
      passed
    end

    # Convenience method for calling +assert+ with its +halting+ argument set to true.
    #
    # @param [String] msg The message to use in the log/error if the assertion fails.
    # @return [Boolean] True if the assertion succeeds, false otherwise.
    def halting_assert(msg, &block)
      assert(msg, halting: true, &block)
    end

    # Behavior on failed assertion. Marks the current automation as failed and records failure information.
    #
    # @raise [AssertionFailedError] If +halting+ AND the assertion raises or returns something other than true.
    #
    # @param [String] assert_msg The message to use in the log/error if the assertion fails.
    # @param [Boolean] halting If true, raise the AssertionFailedError; otherwise, log message at the error level.
    # @param [Integer/String/Array/Hash] expected, represents the value we are expecting as a part of assertion to be
    # logged to output file
    # @param [Integer/String/Array/Hash] actual, represents the actual value identified in test execution to be logged
    def on_failed_assertion(assert_msg, halting, expected, actual)
      @result.failure # mark Automation as failed
      raise AssertionFailedError, assert_msg if halting
      log = "Assertion failed: #{assert_msg}"
      # If we have expected or actual values specified, log them as a part of failure
      log << " - Expected values: #{expected}, Actual values: #{actual}" if actual || expected
      @logger.error(log)
    end
  end
end
