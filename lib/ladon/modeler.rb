require 'set'
require 'ladon/contexts'
require 'ladon/modeler/data/config'
require 'ladon/modeler/errors'
require 'ladon/modeler/states'
require 'ladon/modeler/transitions'

module Ladon
  module Modeler
    # Used to model software as a graph of connected states and transitions.
    class Graph
      module HasStates
        def init_states
          @states ||= Set.new
        end

        def states
          @states.clone
        end

        # TODO
        def valid_state?(state_class)
          state_class.is_a?(Class) && state_class < State
        end

        # Loads the given +state_class+ into this state machine.
        #
        # If the +state_class+ has a +when_loaded_by(loader)+ hook defined, this method will trigger it.
        #
        # Raises an error if the +state_class+ is already loaded.
        #
        # Returns true if the state was newly loaded, false if it was already loaded.
        def load_state_type(state_class)
          raise InvalidStateTypeError.new(state_class) unless valid_state?(state_class)
          return false if state_loaded?(state_class)
          @states.add(state_class)

          load_transitions(state_class) if @eager && self.respond_to?(:load_transitions)
          state_class.when_loaded_by(self) if state_class.respond_to?(:when_loaded_by)
          return true
        end

        # Determines if the given +state_class+ is loaded as a state in this FSM.
        def state_loaded?(state_class)
          @states.include?(state_class)
        end

        # Count the number of states loaded in this FSM.
        def state_count
          @states.size
        end
      end

      module HasTransitions
        def init_transitions
          @transitions ||= Hash.new { |h, k| h[k] = Set.new }
        end

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
            transitions.each {|transition| load_state_type(transition.identify_target_state_type)}
          end
          true
        end

        def add_transitions(state_class, transitions)
          grouped = transitions.group_by { |transition| transition.is_a?(Ladon::Modeler::Transition) }
          on_invalid_transitions(grouped[false]) if grouped.key?(false)
          @transitions[state_class] |= grouped[true] if grouped.key?(true)
        end

        # Handles when invalid transitions are encountered by the model.
        # Does nothing by default.
        def on_invalid_transitions(transitions)
        end

        # Determines if the given +state_class+ has had its transitions loaded into this FSM.
        def transitions_loaded?(state_class)
          @transitions.key?(state_class)
        end

        # Counts the number of transitions available from +state_class+.
        def transition_count_for(state_class)
          @transitions[state_class].size
        end
      end

      include Ladon::HasContexts
      include HasStates
      include HasTransitions

      attr_accessor :eager

      def initialize(config)
        raise StandardError, 'Must be a Modeler config!' unless config.is_a?(Ladon::Modeler::Config)
        @eager = config.eager
        init_states
        init_transitions
        self.contexts = config.contexts

        load_state_type(config.start_state) unless config.start_state.nil?
      end

      # Merges the +target+ provided into this FSM instance.
      def merge(target)
        raise InvalidMergeError, 'Instances to merge are not of the same Class' unless self.class.eql?(target.class)
        target.states.each {|state| load_state_type(state)}
        target.transitions.each {|state, trans_set| transitions[state].merge(trans_set)}
        merge_contexts(target.contexts)
      end
    end

    # Facilitates Finite State Machine modeling.
    class FiniteStateMachine < Graph

      # Creates a new +FiniteStateMachine+ model instance.
      def initialize(config)
        super(config)

        @current_state = nil
        use_state(config.start_state) unless config.start_state.nil?
      end

      # Including classes must override this method.
      def use_state(state_class)
        load_state_type(state_class) unless state_loaded?(state_class)
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
        use_state(target.identify_target_state_type)
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
