require 'set'
require 'ladon/modeler/errors'
require 'ladon/modeler/states'
require 'ladon/modeler/transitions'

module Ladon
  module Modeler
    # Facilitates Finite State Machine modeling.
    class FiniteStateMachine
      include States::HasStates
      include Transitions::HasTransitions

      attr_accessor :eager
      attr_reader :contexts
      attr_reader :current_state

      # Creates a new +FiniteStateMachine+ model instance.
      def initialize(start_state: nil, eager: false, contexts: {})
        @states = Set.new # Set of state classes loaded into this model
        @transitions = Hash.new {|h, k| h[k] = Set.new}
        @current_state = nil

        @eager = eager
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
        other_cls = target.class
        raise InvalidMergeError, "Can't merge #{target.type} into #{self.type}" unless self.class.eql?(other_cls)
        target.states.each {|state| self.load_state_type(state)}
        target.transitions.each {|state, trans_set| @transitions[state].merge(trans_set)}
        @contexts.merge(target.contexts) {|_, my_val, _| my_val} # merge, keeping current value for any conflicts
        set_contexts_for(self)
      end

      # Gets the name of the current +FiniteStateMachine+ class type, without any leading module names.
      # If the class is anonymous, this method will indicate as much and identify the type as the class' string repr.
      def type
        class_name = self.class.name
        return class_name.split('::').last || '' unless class_name.nil?
        return "Anonymous: #{self.class}"
      end

      # Take the currently known contexts and inject them into the +target+.
      def set_contexts_for(target)
        @contexts.each {|name, obj| target.instance_variable_set("@#{name.to_s}", obj)}
      end

      # Including classes must override this method.
      def make_current_state(state_class)
        raise StandardError, "No known state #{state_class}!" unless state_loaded?(state_class)
        @current_state = state_class.new
        set_contexts_for(@current_state)
      end

      # TODO
      def make_transition(&block)
        #prefiltered_transitions = prefiltered_transitions_for(@current_state, &block)
        prefiltered_transitions = prefiltered_transitions(transitions_for(@current_state), &block)
        valid_transitions = available_transitions(prefiltered_transitions)
        target = selection_strategy(valid_transitions)
        err_msg = 'Selection strategy did not return a single transition!'
        raise StandardError, err_msg unless target.is_a?(Transition)
        make_current_state(target.make_transition)
      end

      # Method to select transition to take, out of a set of currently valid transitions.
      # The base +FiniteStateMachine+ implementation expects this function to return
      # a single +Ladon::Modeler::Transition+ instance in +transition_to+.
      def selection_strategy(transition_options)
        raise StandardError, 'Must implement selection_strategy method!'
      end
    end
  end
end
