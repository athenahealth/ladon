module Ladon
  # Represents arbitrary flags/arguments given to a Ladon model or automation.
  class Flags

    # Create a new +Flags+ instance. All +Flags+ instances are frozen upon instantiation.
    #
    # @param [Hash] in_hash Optional hash used to fill out the new +Flags+ instance.
    def initialize(in_hash: nil)
      @flags = {}
      if in_hash.is_a?(Hash)
        in_hash.each { |key, val| @flags[key] = val }
      end

      # once created, flags should not be modified
      @flags.freeze
      self.freeze
    end

    # Get the value associated with a specified flag.
    #
    # @param [Object] flag The flag to load.
    # @param [Object] default_to Defaut value to assume if the given +flag+ isn't found.
    # @return [Object] The object registered with the given +flag+ name if it exists, else +default_to+.
    def get(flag, default_to:)
      @flags.fetch(flag, default_to)
    end
  end
end