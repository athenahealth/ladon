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
  end
end