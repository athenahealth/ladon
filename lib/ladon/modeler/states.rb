module Ladon
  module Modeler
    module States
      class State
        # Class-level method defining the transitions that are available from a given state type.
        def self.transitions
          raise StandardError, 'The transitions method is not implemented!'
        end
      end

      # Default state collection implementation for FiniteStateMachine and subclasses.
      module HasStates

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
          raise StandardError, "#{state_class} is not a State" unless state_class.is_a?(Class) && state_class < State
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
    end
  end
end
