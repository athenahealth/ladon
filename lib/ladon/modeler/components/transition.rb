module Ladon
  module Modeler
    # Used to model when and how modeled software can execute a change of State.
    #
    # @attr_reader [Hash<Object, Object>] metadata Arbitrary key:value pairs associated with the transition.
    # @attr_reader [Boolean] target_loaded True if the transition's target state type loader has been run.
    class Transition
      attr_reader :metadata, :target_loaded
      alias target_loaded? target_loaded

      # Create a new Transition instance, optionally specifying a block to customize the transition.
      #
      # @yield [new_transition] The transition instance being created.
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
      # Overwrites any existing metadata associated with the given +key+.
      #
      # @param [Object] key The key to associate to a value.
      # @param [Object] value The value to associate with the given +key+.
      #
      # @return [Object] The +value+ argument provided to this method.
      def meta(key, value)
        @metadata[key] = value
      end

      # Retrieves the metadata associated with the given +key+.
      #
      # @return [Object] The value currently mapped to the given +key+.
      def meta_for(key)
        @metadata[key]
      end

      # Use this method to define a block that will return true when this transition is valid to execute.
      # If *any* block defined in this manner returns true, the transition will be considered executable.
      # These blocks are leveraged by +valid_for?+ to determine if this transition is available.
      #
      # @raise [BlockRequiredError] if called without a block.
      #
      # @return [Proc] The block that was given to this method.
      def when(&block)
        raise BlockRequiredError, 'Required block was not provided!' unless block_given?
        @when_blocks << block
      end

      # Use this method to define a block that will be called when executing this transition.
      # Any number of blocks may be specified in this manner. These blocks will be evaluated in the order
      # they were defined on the transition. These blocks are leveraged by +make_transition+ to execute this transition.
      #
      # @raise [BlockRequiredError] if called without a block.
      #
      # @return [Proc] The block that was given to this method.
      def by(&block)
        raise BlockRequiredError, 'Required block was not provided!' unless block_given?
        @by_blocks << block
      end

      # Determine if this transition is valid given the +current_state+. A
      # transition is valid if it has no +when_blocks+, or at least one of its
      # +when_blocks+ returns true.
      #
      # @param [Ladon::Modeler::State] current_state Instance of current state to validate against.
      # @return [Boolean] True if the transition is found to be currently valid, false otherwise.
      def valid_for?(current_state)
        @when_blocks.empty? || @when_blocks.any? { |condition| condition.call(current_state) == true }
      end

      # Execute this transition. If the target state has not been loaded, this method will load it.
      #
      # *Warning:* the ability to specify multiple "by" blocks is primarily a convenience.
      # Since *all* by blocks will be executed in context of the +current_state+, only the
      # *last* by block should actually cause the state change (otherwise, the +current_state+
      # may be invalid when given to subsequent "by" blocks.)
      #
      # @param [Ladon::Modeler::State] current_state Instance of current state to execute against.
      # @return [Array<Object>] An array containing the return value of each "by" block.
      def execute(current_state)
        load_target_state_type
        @by_blocks.map { |executor| executor.call(current_state) }
      end

      # The +&block+ given to this method will be used as the routine that should load
      # the transition's target state type into the Ruby interpreter.
      #
      # Running this block should guarantee that the return value of +identify_target_state_type+
      # will be resolvable and not result in a reference error.
      #
      # @raise [BlockRequiredError] if called without a block.
      # @raise [AlreadyLoadedError] if called when the target state type has already been loaded.
      def to_load_target_state_type(&block)
        raise BlockRequiredError, 'Required block was not provided!' unless block_given?
        raise AlreadyLoadedError, 'Already loaded!' if target_loaded?
        @loader = block
      end

      # Runs the +@loader+ Proc that was specified via +to_load_target_state_type+.
      # Short circuits execution if the target state type is already loaded.
      #
      # @raise [NoMethodError] if called without a +@loader+ defined.
      # @return [Boolean] True if the target state type is loaded.
      def load_target_state_type
        return true if target_loaded?
        @loader.call
        @target_loaded = true
      end

      # The +&block+ given to this method will be used as the routine that can be run
      # to get a reference to the target state type's Class.
      #
      # @raise [BlockRequiredError] if called without a block.
      # @raise [AlreadyLoadedError] if called when the target state type has already been loaded.
      def to_identify_target_state_type(&block)
        raise BlockRequiredError, 'Required block was not provided!' unless block_given?
        raise AlreadyLoadedError, 'Already loaded!' if target_loaded?
        @identifier = block
      end

      # Returns a reference to the state type of this transition's target.
      # Calls the identifier block specified via +to_identify_target_state_type+ to
      # ensure that the target is loaded before exposing the bare reference to it.
      #
      # @return [Class] Reference to the target State class type.
      def identify_target_state_type
        load_target_state_type
        @target_state_type ||= @identifier.call
      end
    end
  end
end
