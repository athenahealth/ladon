module Ladon
  module Modeler
    module Transitions
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
          @by_blocks.each {|executor| executor.call(current_state)}
          return identify_target_state_type
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

      # Default transition implementations.
      # Expects classes that include it to also include +Ladon::Modeler::States:HasStates+,
      # or at least to implement the API exposed by that module.
      module HasTransitions

        # Gets a cloned copy of the loaded set of transitions.
        def transitions
          @transitions.clone
        end

        # Load the transitions defined by the given +state_class+.
        # Returns false if the transitions were already loaded for +state_class+, true otherwise.
        def load_transitions(state_class)
          raise StandardError, "No known state #{state_class}!" unless state_loaded?(state_class)
          return false if transitions_loaded?(state_class)

          transitions = state_class.transitions
          raise StandardError, 'Transitions method must return an enumerable!' unless transitions.respond_to?(:each)
          add_transitions(state_class, transitions)
          if @eager && respond_to?(:load_state_type)
            transitions.each {|transition| load_state_type(transition.target_state_type)}
          end
          return true
        end

        def add_transitions(state_class, transitions)
          grouped = transitions.group_by {|trans| trans.is_a?(Ladon::Modeler::Transitions::Transition)}
          self.invalid_transitions(grouped[false]) if grouped.key?(false)
          @transitions[state_class] |= grouped[true]
        end

        # Handles when invalid transitions are encountered by the model.
        # Does nothing by default.
        def invalid_transitions(transitions)
        end

        # Determines if the given +state_class+ has had its transitions loaded into this FSM.
        def transitions_loaded?(state_class)
          @transitions.key?(state_class)
        end

        # Lists the transitions available from +state_class+.
        def transitions_for(state_class)
          @transitions[state_class].clone
        end

        # Counts the number of transitions available from +state_class+.
        def transition_count_for(state_class)
          @transitions[state_class].size
        end

        # Filter the given list of transitions based on the model prefilter and current state.
        def prefiltered_transitions(transitions, &block)
          transitions.select do |transition|
            # keep transitions that pass the filter block (if one is provided) AND pass the model-level prefilter
            (!block_given? || block.call(transition)) && passes_prefilter?(transition)
          end
        end

        # Model-level strategy for prefiltering  transition, leveraged by +make_transition+.
        # Is an acceptance strategy; this method should return true unless you want to filter OUT the transition.
        def passes_prefilter?(transition)
          true
        end

        # Get the transitions available from the current state instance.
        # Only available if +current_state+ is instantiated.
        def available_transitions(transition_options)
          raise StandardError, 'No current state to validate against!' if current_state.nil?
          transition_options.select {|transition| transition.valid_for?(current_state)}
        end
      end
    end
  end
end