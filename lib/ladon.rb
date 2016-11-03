require 'ladon/_version'
require 'ladon/modeler'
require 'ladon/automator'

module Ladon
  class Flags
    def initialize(in_hash: nil)
      @flags = {}
      if in_hash.is_a?(Hash)
        in_hash.each { |key, val| @flags[key.to_sym] = val }
      end

      # once created, don't allow modification
      @flags.freeze
      self.freeze
    end

    def get(flag_name, default_value:)
      @flags.fetch(flag_name.to_sym, default_value)
    end
  end
end
