module Ladon
  module Modeler
    # Allows for modeling when and how a +FiniteStateMachine+ can change its current state
    # from one specified state to another.
    class Transition
      attr_reader :metadata
      attr_reader :target_loaded
      alias_method :target_loaded?, :target_loaded

      # Create a new Transition instance, optionally specifying a block to customize the transition.
      def initialize
        @when_blocks = []
        @by_blocks = []
        @metadata = {}

        @identifier = nil
        @target_state_type = nil
        @target_loaded = false

        yield(self) if block_given?
      end

      # Define metadata associated with this transition.
      def meta(key, value)
        @metadata[key] = value
      end

      # Allow access to metadata information
      def meta_for(key)
        @metadata[key]
      end

      # Define a block that will return true when this transition is actionable.
      # If *any* block defined in this manner returns true, the transition
      # will be considered executable.
      #
      # These blocks are leveraged by +valid_for?+ to determine if this transition is available.
      def when(&block)
        raise StandardError, 'Required block was not provided!' unless block_given?
        @when_blocks << block
      end

      # Define a block that will be called when activating this transition.
      # Any number of blocks may be specified in this manner. When executing this transition,
      # these blocks will be evaluated in the order they were defined on the transition.
      #
      # These blocks are leveraged by +make_transition+ to execute this transition.
      def by(&block)
        raise StandardError, 'Required block was not provided!' unless block_given?
        @by_blocks << block
      end

      # Determine if this transition is valid given the +current_state+.
      #
      # A transition is valid if it has no +when_blocks+, or at least one of its
      # +when_blocks+ returns true.
      def valid_for?(current_state)
        @when_blocks.empty? || @when_blocks.any? { |condition| condition.call(current_state) }
      end

      # Executes this transition.
      def execute(current_state)
        return_vals = @by_blocks.map { |executor| executor.call(current_state) }
        return [identify_target_state_type, return_vals]
      end

      # The +block+ given to this method will be used as the routine that should load
      # the transition's target state type into the Ruby interpreter.
      #
      # Running this block should guarantee that the return value of +identify_target_state_type+
      # will be resolvable and not result in a reference error.
      def to_load_target_state_type(&block)
        raise StandardError, 'Required block was not provided!' unless block_given?
        raise StandardError, 'Already loaded!' if target_loaded?
        @loader = block
      end

      def load_target_state_type
        return true if target_loaded?
        @loader.call
        @target_loaded = true
      end

      def to_identify_target_state_type(&block)
        raise StandardError, 'Required block was not provided!' unless block_given?
        raise StandardError, 'Already loaded!' if target_loaded?
        @identifier = block
      end

      # Returns the state type of this transition's target.
      # Must have called +load_target_state_type+ prior to calling this method.
      #
      # Calls the identifier block specified via +to_identify_target_state_type+
      def identify_target_state_type
        raise StandardError, 'Target state type not loaded yet!' unless target_loaded?
        @target_state_type ||= @identifier.call
      end
    end
  end
end