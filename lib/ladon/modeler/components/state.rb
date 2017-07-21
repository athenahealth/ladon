module Ladon
  module Modeler
    # The base type for representing Nodes/States in Ladon graph models.
    #
    # @abstract
    class State
      class << self
        attr_accessor :class_transitions
      end

      # Class-level method defining the transitions that are available from a given state type.
      #
      # @return [Enumerable<Ladon::Modeler::Transition>] List-like object containing Transition
      #   instances that are valid from instances of this State type.
      def self.transitions
        ts = @class_transitions || []
        parent_class_transitions = superclass < Ladon::Modeler::State ? superclass.transitions : []

        return ts + parent_class_transitions
      end

      # Class-level method for declaring a new transition that will be available from a given state
      # type.
      #
      # @param [String] target_name The name of the transition target class.
      # @yield [Ladon::Modeler::Transition] The transition instance being created.
      def self.transition(target_name)
        @class_transitions = [] if @class_transitions.nil?
        @class_transitions.push(Ladon::Modeler::Transition.new do |t|
          t.target_name = target_name
          yield(t) if block_given?
        end)
      end

      # Method used by State instances to determine whether or not they are currently valid.
      # The +FiniteStateMachine+ leverages this method when making Transitions to confirm that the new state
      # is accurate to the software
      #
      # @abstract
      #
      # @return [Boolean] true by default. Subclasses should redefine to implement custom verification semantics.
      def verify_as_current_state?
        true
      end
    end
  end
end
