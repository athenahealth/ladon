require 'ladon/modeler/graph'

module Ladon
  module Modeler
    # Facilitates Finite State Machine modeling.
    class FiniteStateMachine < Graph

      # Creates a new +FiniteStateMachine+ model instance.
      def initialize(config = Ladon::Modeler::Config.new)
        super
        @current_state = nil
      end

      # Override if you need to define new behaviors.
      def new_state_instance(state_class)
        @current_state = state_class.new
      end

      # Including classes must override this method.
      def use_state_type(state_class, strategy: LoadStrategy::LAZY)
        load_state_type(state_class, strategy: strategy) unless state_loaded?(state_class)
        @current_state = new_state_instance(state_class)
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

    # Alias FiniteStateMachine to FSM so users have the option to save typing effort.
    FSM = FiniteStateMachine
  end
end
