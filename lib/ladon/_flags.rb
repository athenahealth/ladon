module Ladon
  # Represents arbitrary flags/arguments given to a Ladon model or automation.
  class Flags
    # Create a new +Flags+ instance. All +Flags+ instances are frozen upon instantiation.
    #
    # @param [Hash] in_hash Optional hash used to fill out the new +Flags+ instance.
    def initialize(in_hash: nil)
      @flags = {}
      in_hash.each { |key, val| @flags[key.to_sym] = val } if in_hash.is_a?(Hash)

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
      @flags.fetch(flag.to_sym, default_to)
    end

    # Return the hash-formatted +@flags+ attribute of flags
    # @return [Hash] value of the flags attribute
    def to_h
      @flags
    end

    # Create a string-formatted version of flags
    # @return [String] printable string containing flags attributes in a neat format
    def to_s
      @flags.map { |flag, value| "#{flag}  => #{value}" }.join("\n")
    end
  end
end
