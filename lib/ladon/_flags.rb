module Ladon
  # Represents arbitrary flags/arguments to a Ladon model or automation.
  class Flags
    def initialize(in_hash: nil)
      @flags = {}
      if in_hash.is_a?(Hash)
        in_hash.each { |key, val| @flags[key.to_sym] = val }
      end

      # once created, flags should not be modified
      @flags.freeze
      self.freeze
    end

    def get(flag, default_to:)
      @flags.fetch(flag.to_sym, default_to)
    end
  end
end