module Ladon
  module Modeler
    # Defines approach to loading states/transitions in +Ladon::Modeler::Graph+ instances.
    # Documentation uses the term "components" to refer to states and transitions.
    module LoadStrategy
      NONE = :none # Strategy: do not perform the component load operation at all.
      LAZY = :lazy # Strategy: load only the target component (do not load connected components.)
      CONNECTED = :connected # Strategy: load the target component AND the components directly connected to it.
      EAGER = :eager # Load the target component and follow all connected components until no more are encountered.

      ALL = [NONE, LAZY, CONNECTED, EAGER].freeze # Collection of all valid LoadStrategy constants.

      # Defines the strategy to use for loading components connected to the subject of a component load operation.
      NESTING = {
          NONE => NONE,
          LAZY => NONE,
          CONNECTED => LAZY,
          EAGER => EAGER
      }.freeze

      # Convenience method for getting the nested LoadStrategy for a given LoadStrategy type.
      #
      # @raise [ArgumentError] If +load_strategy+ is invalid.
      #
      # @param [LoadStrategy] load_strategy An object that *should* be a value from +LoadStrategy::ALL+.
      # @return [LoadStrategy] The nested/recursive strategy type for the given LoadStrategy type.
      # @raise [StandardError] If given an argument that is not a LoadStrategy type.
      def self.nested_strategy_for(load_strategy)
        raise ArgumentError, 'Not a load strategy!' unless ALL.include?(load_strategy)
        NESTING[load_strategy]
      end
    end
  end
end