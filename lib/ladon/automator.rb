# Ladon is a framework designed for modeling and automating interaction with software.
# The framework consists of three layers of components, with each layer building on the previous layer
# in order to create a clear separation of concerns.
#
# The Automator component is the second layer, building upon the Modeler component.
# Conceptually, Automator is intended to facilitate automated interaction with software via that software's
# model, which should be written using Ladon's Modeler.
#
# The Automator is used to configure a _single_ automated interaction with the software (think of it as
# a single session using the software). If you've reached the point where you need to issue multiple
# Automator runs, go look at the Orchestrator component.

require 'ladon/contexts'
require 'ladon/automator/api/assertions'
require 'ladon/automator/data/config'
require 'ladon/automator/data/result'
require 'ladon/automator/logging/logger'
require 'ladon/automator/timing/timer'

module Ladon
  module Automator
    # The Automation is used to harness a Ladon model and use it to power
    # automated interaction with the software it models.
    #
    # During this automation, you are able to make assertions, maintain
    # an activity log, and measure the observable behaviors of the software.
    class Automation
      include Ladon::HasContexts
      include API::Assertions

      attr_reader :config, :result

      SETUP_PHASE = :setup
      EXECUTE_PHASE = :execute
      TEARDOWN_PHASE = :teardown

      # Create an instance of AutomationRun based on the +config+ provided.
      def initialize(config)
        raise StandardError, 'Automation requires a Ladon::Automator::Config' unless config.is_a?(Ladon::Automator::Config)
        @config = config
        @result = Result.new(config)
        @logger = @result.logger
        @timer = @result.timer

      end

      def run
        raise StandardError, "#{EXECUTE_PHASE} not implemented!" unless respond_to?(EXECUTE_PHASE)

        setup_phase
        execute_phase
        teardown_phase

        return @result
      end

      # Subclass implementations should override this method to return false if the subclass is intended as
      # a concrete, runnable Automation implementation.
      #
      # Ladon utilities will not attempt to execute Automations of any class that returns true for this method.
      def self.abstract?
        true
      end

      # Given an arbitrary code block, this method will execute that block in a rescue construct.
      # Should be used to ensure that the block
      def sandbox(activity_name, &block)
        raise StandardError, 'No block given!' unless block_given?

        begin
          block.call
        rescue => ex
          on_error(ex, activity_name)
        end
      end

      private

      # Runs the +setup+ component of the automation.
      # Will be a no-op if the Automation has no +setup+ method to harness.
      def setup_phase
        do_phase(SETUP_PHASE, skip: !respond_to?(SETUP_PHASE), skip_msg: "No #{SETUP_PHASE} method detected.")
      end

      # The +execute+ method is idiomatically intended to house the interesting portion of the automation run.
      # Automation implementations *MUST* define an +execute+ method.
      def execute_phase
        do_phase(EXECUTE_PHASE, skip: !@result.success?, skip_msg: 'skipped due to existing error or failure')
      end

      # Subclasses should define their cleanup behaviors in this method.
      def teardown_phase
        do_phase(TEARDOWN_PHASE, skip: !respond_to?(TEARDOWN_PHASE), skip_msg: "No #{TEARDOWN_PHASE} method detected.")
      end

      # Run a phase of the Automation script, auto-timing the duraction of its execution.
      # The phase will be sandboxed such that an unrescued error during the phase will not crash the entire execution.
      def do_phase(phase, skip: false, skip_msg: nil)
        return @logger.warn("#{phase} skipped: '#{skip_msg}'") if skip

        @timer.for(phase) do
          @logger.info("Starting #{phase}")
          sandbox(phase) do # mark Automation a failure if a phase fails
            self.send(phase)
            @logger.info("#{phase} completed normally")
          end
        end
      end

      # Behavior to exhibit when a test run phase has an error that is not rescued by the test script's implementation.
      #
      # * Arguments:
      #   - +err+:: The error that was not
      #   - +phase+:: String identifying the the phase that errored out.
      #   - +fail_test+:: If true, sets the test run to a FAILURE state.
      def on_error(err, phase)
        @result.error
        # TODO: convert log into record of objects?
        @logger.error(error_to_array(err, description: "#{err.class} in #{phase}: #{err}"))
      end

      # Takes an Error instance and converts it to an array of message lines.
      #
      # * Arguments:
      #   - +msg+:: A message to put at the beginning of the message array
      #   - +err+:: The Error to convert to message lines
      #
      # * Returns:
      #   - An Array of strings containing error information, with index = 0 being the first line of the info.
      def error_to_array(err, description: nil)
        msglines = err.backtrace
        msglines.unshift(description) unless description.nil? || description.empty?
        return msglines
      end
    end

    # Class for Automation driven through a Ladon Modeler model.
    class ModelAutomation < Automation

      # Create an instance based on the +config+ provided.
      def initialize(config)
        raise StandardError, 'Ladon Modeler must be present' unless defined?(Ladon::Modeler)
        super
        @model = self.class.target_model # set up the model
        raise StandardError, 'The model must be a Ladon FSM' unless @model.is_a?(Ladon::Modeler::FiniteStateMachine)
      end

      # Subclasses _MUST_ override this method. This method should return an instance of
      # +Ladon::Modeler::FiniteStateMachine+ that will power this automation.
      def self.target_model
        raise StandardError, 'The target_model method is not implemented!'
      end
    end

    # TODO
    #class Orchestrator < Automation
    #end
  end
end