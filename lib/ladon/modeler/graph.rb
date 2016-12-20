require 'set'
require 'ladon/modeler/components/load_strategy'
require 'ladon/modeler/components/state'
require 'ladon/modeler/components/transition'

module Ladon
  module Modeler
    # Used to model software as a graph of states connected by various transitions.
    #
    # @attr_reader [Set] states Set containing the +State+ classes loaded in this Graph.
    # @attr_reader [Hash] transitions Hash mapping loaded +State+ classes to loaded +Transition+ instances associated.
    class Graph < Bundle
      attr_reader :states, :transitions

      # Create a new +Graph+ instance.
      #
      # @raise [ArgumentError] If the +config+ is not a Ladon::Config instance.
      #
      # @param [Ladon::Config] config The object providing configuration for this new Graph model.
      # @return [Graph] The new graph instance.
      def initialize(config: Ladon::Config.new, timer: nil, logger: nil)
        super(config: config, timer: timer, logger: logger)
        @states = Set.new
        @transitions = Hash.new { |h, k| h[k] = Set.new }
      end

      # Count the number of states loaded in this FSM.
      #
      # @return [Fixnum] The number of state types loaded into this Graph.
      def state_count
        @states.size
      end

      # Determines if the given +state_class+ is loaded as a state in this FSM.
      # If +valid_state?+ wouldn't return true for the +state_class+, this *should* return false, too.
      #
      # @param [Object] state_class The potential state to check against the graph's loaded state set.
      # @return [Boolean] True if the +state_class+ is loaded in this graph, false otherwise.
      def state_loaded?(state_class)
        @states.include?(state_class)
      end

      # Determines if the given +state_class+ is a valid state according to this graph implementation.
      #
      # @param [Object] state_class The potential state to check against the graph's supported state types.
      # @return [Boolean] True if the +state_class+ is a valid state type, false otherwise.
      def valid_state?(state_class)
        state_class.is_a?(Class) && state_class < State
      end

      # Determines if the given +state_class+ has had its transitions loaded into this FSM.
      #
      # @param [Object] state_class The potential state to check against the graph's loaded transition mappings.
      # @return [Boolean] True if the +state_class+ is loaded in this graph, false otherwise.
      def transitions_loaded?(state_class)
        state_loaded?(state_class) && @transitions.key?(state_class)
      end

      # Counts the number of transitions available in this graph from +state_class+.
      # If the state doesn't exist or has not had its transitions loaded, this will return 0.
      #
      # @param [Object] state_class The potential state to check against the graph's loaded transition mappings.
      # @return [Fixnum] The number of transitions with +state_class+ as the source state type.
      def transition_count_for(state_class)
        return 0 unless transitions_loaded?(state_class)
        @transitions[state_class].size
      end

      # Handler for when invalid transitions are encountered by the model.
      #
      # @abstract
      #
      # @param [Array<Transition>] transitions List of detected invalid transitions.
      def on_invalid_transitions(transitions); end

      # Loads the given +state_class+ into this state machine.
      #
      # @raise [InvalidStateTypeError] If +state_class+ is not a valid state type for this graph.
      #
      # @param [Object] state_class The potential state to load into this graph.
      # @param [LoadStrategy] strategy The strategy from LoadStrategy::ALL to use for this load operation.
      # @return [Boolean] True if the state is now (or was already) loaded, false otherwise.
      def load_state_type(state_class, strategy: LoadStrategy::LAZY)
        raise InvalidStateTypeError, state_class unless valid_state?(state_class)
        return true if state_loaded?(state_class)
        return false if !LoadStrategy::ALL.include?(strategy) || strategy == LoadStrategy::NONE

        @states.add(state_class)
        load_transitions(state_class, strategy: LoadStrategy.nested_strategy_for(strategy))
        true
      end

      # Load the transitions defined by the given +state_class+.
      #
      # *Note:* this is purely for loading transitions via the 'transitions' method of +state_class+.
      # If you want to manually add transitions, see the +add_transitions+ method.
      #
      # @raise [ArgumentError] If +state_class+ is not a state type known to this graph.
      #
      # @param [Object] state_class The potential state whose transitions are being loaded into this graph.
      # @param [LoadStrategy] strategy The strategy from LoadStrategy::ALL to use for this load operation.
      # @return [Boolean] True if the state's transitions are now (or were already) loaded, false otherwise.
      def load_transitions(state_class, strategy: LoadStrategy::LAZY)
        raise ArgumentError, "No known state #{state_class}!" unless state_loaded?(state_class)
        return true if transitions_loaded?(state_class)
        return false if strategy == LoadStrategy::NONE

        added = add_transitions(state_class, state_class.transitions)

        unless added.empty?
          next_strategy = LoadStrategy.nested_strategy_for(strategy)
          unless next_strategy == LoadStrategy::NONE
            added.each { |transition| load_state_type(transition.target_type, strategy: next_strategy) }
          end
        end

        true
      end

      # Add the +transitions+ to the set associated with the given +state_class+.
      # Calls +on_invalid_transitions+ with the invalid transitions that were detected, if any are detected.
      #
      # @raise [ArgumentError] If +state_class+ is not a state type known to this graph.
      #
      # @param [Class] state_class The state to associate the +transitions+ with.
      # @param [Set<Transition>] transitions The potential transitions to load into this graph.
      # @return [Set<Ladon::Modeler::Transition>] The transitions that were loaded and associated with +state_class+.
      def add_transitions(state_class, transitions)
        raise ArgumentError, "No known state #{state_class}!" unless state_loaded?(state_class)
        valid_groups = transitions.group_by { |transition| transition.is_a?(Ladon::Modeler::Transition) }
        on_invalid_transitions(valid_groups[false]) if valid_groups.key?(false)

        added = Set.new(valid_groups.fetch(true, [])) - @transitions[state_class] # detect the truly "new" transitions
        @transitions[state_class] += added # add them
        added # return them
      end

      # Merges the +target+ provided into this graph instance.
      # Only allowed on graph instances of the same Class.
      #
      # @raise [InvalidMergeError] If this graph and the +target+ are not instances of the same Class.
      #
      # @param [Ladon::Modeler::Graph] target The graph to merge into this graph.
      def merge(target)
        raise InvalidMergeError, 'Instances to merge are not of the same Class' unless self.class.eql?(target.class)
        target.states.each { |state| load_state_type(state) }
        target.transitions.each { |state, trans_set| transitions[state].merge(trans_set) }
      end
    end
  end
end
