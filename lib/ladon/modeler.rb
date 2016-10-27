require 'set'
require 'ladon/modeler/errors'
require 'ladon/modeler/states'
require 'ladon/modeler/transitions'

module Ladon
  module Modeler
    # Used to model software as a graph of connected states and transitions.
    class Graph
      module HasStates
        # TODO
        def valid_state?(state_class)
          state_class.is_a?(Class) && state_class < State
        end

        # Can respond with a duplicate representing the state data in the state machine.
        def states
          @states.clone
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
          on_invalid_transitions(grouped[false]) if grouped.key?(false)
          @transitions[state_class] |= grouped[true]
        end

        # Handles when invalid transitions are encountered by the model.
        # Does nothing by default.
        def on_invalid_transitions(transitions)
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
      end

      include HasStates
      include HasTransitions

      attr_accessor :eager

      def initialize(start_state: nil, eager: false, contexts: {})
        @states = Set.new # Set of state classes loaded into this model
        @transitions = Hash.new {|h, k| h[k] = Set.new}
        @eager = eager
      end

      # Merges the +target+ provided into this FSM instance.
      def merge(target)
        raise InvalidMergeError, 'Instances to merge are not of the same Class' unless self.class.eql?(target.class)
        target.states.each {|state| self.load_state_type(state)}
        target.transitions.each {|state, trans_set| @transitions[state].merge(trans_set)}
      end

      # "Follow" a transition to get the type of the state on the other side.
      def follow_transition(transition)
        return transition.identify_target_state_type
      end
    end

    # Facilitates Finite State Machine modeling.
    class FiniteStateMachine < Graph
      attr_reader :contexts
      attr_reader :current_state

      # Creates a new +FiniteStateMachine+ model instance.
      def initialize(start_state: nil, eager: false, contexts: {})
        super
        @current_state = nil
        @activity_log = [] # can track model activity

        # contexts: objects available through the model to states/transitions
        # as instance variables
        @contexts = Hash(contexts)
        set_contexts_for(self) unless @contexts.empty?

        unless start_state.nil?
          load_state_type(start_state)
          self.make_current_state(start_state)
        end
      end

      def executing?
        !@current_state.nil?
      end

      # Merges the +target+ provided into this FSM instance.
      def merge(target)
        super(target)
        @contexts.merge(target.contexts) {|_, my_val, _| my_val} # merge, keeping current value for any conflicts
        set_contexts_for(self)
      end

      # Take the currently known contexts and inject them into the +target+.
      def set_contexts_for(target)
        @contexts.each {|name, obj| target.instance_variable_set("@#{name.to_s}", obj)}
      end

      # Including classes must override this method.
      def make_current_state(state_class)
        raise StandardError, "No known state #{state_class}!" unless state_loaded?(state_class)
        @current_state = state_class.new(@contexts)
        return state_class
      end

      # TODO
      def make_transition(&block)
        prefiltered_transitions = prefiltered_transitions(transitions_for(@current_state), &block)
        valid_transitions = available_transitions(prefiltered_transitions)
        target = selection_strategy(valid_transitions)
        err_msg = 'Selection strategy did not return a single transition!'
        raise StandardError, err_msg unless target.is_a?(Transition)
        make_current_state(target.make_transition)
        follow_transition(target)
      end

      # Method to select transition to take, out of a set of currently valid transitions.
      # The base +FiniteStateMachine+ implementation expects this function to return
      # a single +Ladon::Modeler::Transition+ instance in +transition_to+.
      def selection_strategy(transition_options)
        raise StandardError, 'Must implement selection_strategy method!'
      end

      # Get the transitions available from the current state instance.
      # Only available if +current_state+ is instantiated.
      def available_transitions(transition_options)
        raise StandardError, 'No current state to validate against!' if current_state.nil?
        transition_options.select {|transition| transition.valid_for?(current_state)}
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
    end
  end
end
