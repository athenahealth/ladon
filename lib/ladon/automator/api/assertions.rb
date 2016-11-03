module Ladon
  module Automator
    # Defines all of the APIs that are available during automation runs.
    module API
      module Assertions
        class AssertionFailedError < RuntimeError
          def initialize(msg)
            super("Assertion failed: #{msg}")
          end
        end

        def assert(msg, halting: false, &block)
          raise StandardError, 'No assertion block given!' unless block_given?

          begin
            passed = block.call
          rescue => ex
            passed = false
            @logger.error(error_to_array(ex, description: "Error during attempt to evaluate assertion block: #{ex}"))
          end

          # NOTE: we do a check for TRUE instead of TRUTHY so that those who code assertions in blocks
          # are less likely to have flaky assertions due to unintentionally returning something truthy.
          return @logger.info("Assertion passed: '#{msg}'") if passed == true

          on_failed_assertion(msg, halting)
        end

        def halting_assert(msg, &block)
          assert(msg, halting: true, &block)
        end

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
