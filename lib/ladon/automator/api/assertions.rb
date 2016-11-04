module Ladon
  module Automator
    # Defines all of the APIs that are available during automation runs through the +Automation+ instance.
    module API
      # Defines the API for making assertions about the execution behavior of the +Automation+.
      module Assertions
        # Error raised when a +halting_assert+ fails.
        class AssertionFailedError < RuntimeError
          # Create an instance with the given message.
          #
          # @param [String] msg The message to display as part of the Error.
          def initialize(msg)
            super("Assertion failed: #{msg}")
          end
        end

        # Make an assertion by running the given block in a sandbox. If the block raises, the assertion
        # is considered a failure.
        #
        # *Note:* if the block executes without error, it *must* return *true* to be considered
        # a success. This is an explicit design decision: because it is so easy to incidentally return
        # a value, we force asserters to return *true* as the *only* way to indicate "success" of assertion.
        # This should decrease the likelihood of false positive assertions due to incidental return values.
        #
        # @raise [BlockRequiredError] If no block is given.
        # @raise [AssertionFailedError] If the assertion raises or returns something other than true
        #
        # @param [String] msg The message to use in the log/error if the assertion fails.
        # @param [Boolean] halting If true, halt the Automation's execution of its current phase on assertion failure.
        # @return [Boolean] True if the assertion succeeds, false otherwise.
        def assert(msg, halting: false)
          raise BlockRequiredError, 'No assertion block given!' unless block_given?

          begin
            passed = yield
          rescue => ex
            passed = false
            @logger.error(error_to_array(ex, description: "Error during attempt to evaluate assertion block: #{ex}"))
          end

          if passed == true # True vs truthy; see *note* in method doc
            @logger.info("Assertion passed: '#{msg}'")
            return true
          end

          on_failed_assertion(msg, halting)
          false
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
        def on_failed_assertion(assert_msg, halting)
          @result.failure # mark Automation as failed
          if halting
            raise AssertionFailedError, assert_msg
          else
            @logger.error("Assertion failed: #{assert_msg}")
          end
        end
      end
    end
  end
end
