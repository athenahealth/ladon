require 'set'
require 'ladon/contexts'
require 'ladon/modeler/data/config'
require 'ladon/modeler/errors'
require 'ladon/modeler/states'
require 'ladon/modeler/transitions'

module Ladon
  module Modeler
    # Defines approach for  to loading states/transitions.
    module LoadStrategy
      # Do not perform the load operation at all
      NONE = :none
      # Load only the target state or transition; do not auto-load connected states/transitions
      LAZY = :lazy
      # Load the target state or transition; load the connected state or transitions with LAZY strategy
      CONNECTED = :connected
      # Load the target state/transition; recursively load
      EAGER = :eager

      ALL = [NONE, LAZY, CONNECTED, EAGER]
      NESTING = {
          NONE => NONE,
          LAZY => NONE,
          CONNECTED => LAZY,
          EAGER => EAGER
      }

      def self.nested_strategy_for(load_strategy)
        raise StandardError, 'Not a load strategy!' unless ALL.include?(load_strategy)
        NESTING[load_strategy]
      end
    end

    # Used to model software as a graph of connected states and transitions.
    class Graph
      include Ladon::HasContexts
      attr_reader :states, :transitions

      def initialize(config)
        raise StandardError, 'Must be a Modeler config!' unless config.is_a?(Ladon::Modeler::Config)
        @states = Set.new
        @transitions = Hash.new { |h, k| h[k] = Set.new }
        self.contexts = config.contexts

        if config.start_state && LoadStrategy::ALL.include?(config.load_strategy)
          load_state_type(config.start_state, strategy: config.load_strategy)
        end
      end

      # Determines if the given +state_class+ is loaded as a state in this FSM.
      def state_loaded?(state_class)
        @states.include?(state_class)
      end

      # Count the number of states loaded in this FSM.
      def state_count
        @states.size
      end

      # TODO
      def valid_state?(state_class)
        state_class.is_a?(Class) && state_class < State
      end

      # Determines if the given +state_class+ has had its transitions loaded into this FSM.
      def transitions_loaded?(state_class)
        @transitions.key?(state_class)
      end

      # Counts the number of transitions available from +state_class+.
      def transition_count_for(state_class)
        return nil unless transitions_loaded?(state_class)
        @transitions[state_class].size
      end

      # Handles when invalid transitions are encountered by the model.
      # Does nothing by default.
      def on_invalid_transitions(transitions)
      end

      # Loads the given +state_class+ into this state machine.
      #
      # If the +state_class+ has a +when_loaded_by(loader)+ hook defined, this method will trigger it.
      #
      # Raises an error if the +state_class+ is already loaded.
      #
      # Returns true if the state is or was already loaded, false otherwise.
      def load_state_type(state_class, strategy: LoadStrategy::LAZY)
        raise InvalidStateTypeError.new(state_class) unless valid_state?(state_class)
        return true if state_loaded?(state_class)
        return false if strategy == LoadStrategy::NONE

        @states.add(state_class)
        load_transitions(state_class, strategy: LoadStrategy.nested_strategy_for(strategy))
        true
      end

      # Load the transitions defined by the given +state_class+.
      # Returns true if the transitions are loaded or were already loaded, false otherwise.
      def load_transitions(state_class, strategy: LoadStrategy::Lazy)
        raise StandardError, "No known state #{state_class}!" unless state_loaded?(state_class)
        return true if transitions_loaded?(state_class)
        return false if strategy == LoadStrategy::NONE

        transitions = state_class.transitions
        raise StandardError, 'Transitions method must return an enumerable!' unless transitions.respond_to?(:each)
        add_transitions(state_class, transitions)
        next_strategy = LoadStrategy.nested_strategy_for(strategy)
        unless next_strategy == LoadStrategy::NONE
          transitions.each {|transition| load_state_type(transition.identify_target_state_type, strategy: next_strategy)}
        end
        true
      end

      def add_transitions(state_class, transitions)
        raise StandardError, "No known state #{state_class}!" unless state_loaded?(state_class)
        grouped = transitions.group_by { |transition| transition.is_a?(Ladon::Modeler::Transition) }
        on_invalid_transitions(grouped[false]) if grouped.key?(false)
        @transitions[state_class] |= grouped[true] if grouped.key?(true)
      end

      # Merges the +target+ provided into this FSM instance.
      def merge(target)
        raise InvalidMergeError, 'Instances to merge are not of the same Class' unless self.class.eql?(target.class)
        target.states.each { |state| load_state_type(state) }
        target.transitions.each { |state, trans_set| transitions[state].merge(trans_set) }
        merge_contexts(target.contexts)
      end
    end

    # Facilitates Finite State Machine modeling.
    class FiniteStateMachine < Graph

      # Creates a new +FiniteStateMachine+ model instance.
      def initialize(config)
        @current_state = nil
        super(config)

        if config.start_state && LoadStrategy::ALL.include?(config.load_strategy)
          use_state_type(config.start_state, strategy: config.load_strategy)
        end
      end

      # Including classes must override this method.
      def use_state_type(state_class, strategy: LoadStrategy::LAZY)
        load_state_type(state_class, strategy: strategy) unless state_loaded?(state_class)
        @current_state = state_class.new(contexts)
      end

      #
      def current_state(&block)
        return @current_state unless block_given?
        block.call(@current_state)
      end

      # TODO
      def make_transition(&block)
        all_transitions = @transitions[current_state.class]
        prefiltered_transitions = prefiltered_transitions(all_transitions, &block)
        valid_transitions = valid_transitions(prefiltered_transitions)
        target = selection_strategy(valid_transitions)
        raise StandardError, 'Selection strategy did not return a single transition!' unless target.is_a?(Transition)
        target.execute(current_state)
        use_state_type(target.identify_target_state_type)
      end

      # Filter the given list of transitions based on the model prefilter and current state.
      def prefiltered_transitions(transitions_list, &block)
        transitions_list.select do |transition|
          # keep transitions that pass the filter block (if one is provided) AND pass the model-level prefilter
          (!block_given? || block.call(transition) == true) && passes_prefilter?(transition)
        end
      end

      # Model-level strategy for prefiltering  transition, leveraged by +make_transition+.
      # Is an acceptance strategy; this method should return true unless you want to filter OUT the transition.
      def passes_prefilter?(transition)
        true
      end

      # Get the transitions available from the current state instance.
      # Only available if +current_state+ is instantiated.
      def valid_transitions(transition_options)
        raise StandardError, 'No current state to validate against!' if current_state.nil?
        transition_options.select {|transition| transition.valid_for?(current_state)}
      end

      # Method to select transition to take, out of a set of currently valid transitions.
      # The base +FiniteStateMachine+ implementation expects this function to return
      # a single +Ladon::Modeler::Transition+ instance in +transition_to+.
      def selection_strategy(transition_options)
        raise Ladon::MissingImplementationError, 'Must implement selection_strategy method!'
      end
    end
  end
end
