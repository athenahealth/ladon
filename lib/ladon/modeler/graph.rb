require 'set'
require 'ladon/modeler/data/config'
require 'ladon/modeler/components/load_strategy'
require 'ladon/modeler/components/state'
require 'ladon/modeler/components/transition'

module Ladon
  module Modeler
    # Used to model software as a graph of connected states and transitions.
    class Graph
      attr_reader :states, :transitions, :flags

      def initialize(config = Ladon::Modeler::Config.new)
        raise StandardError, 'Graph requires a Ladon::Modeler::Config' unless config.is_a?(Ladon::Modeler::Config)
        @config = config
        @states = Set.new
        @transitions = Hash.new { |h, k| h[k] = Set.new }
        @flags = config.flags
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
      def load_transitions(state_class, strategy: LoadStrategy::LAZY)
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
      end
    end
  end
end
