# frozen_string_literal: true

require 'json'

module Ladon
  # Module to be extended by Classes that will have Flag objects and process them.
  # Classes extending this module must have an instance method named +flags+ that returns the instance's flag values.
  module HasFlags
    # When a class extends this module, have it also include the instance methods defined below.
    def self.extended(base)
      base.send :include, InstanceMethods
    end

    # Get the Flag objects associated with this Class (and parent classes.)
    # @return [Array<Flag>] The flags that apply to this automation (directly and inherited.)
    def all_flags
      my_flags = @flag_objects || []
      my_flags += self.superclass.all_flags if self.superclass < HasFlags::InstanceMethods
      return my_flags
    end

    # Create a new Flag for this class, and automatically track it in an array.
    #
    # @param [String|Symbol] name The name of this flag.
    # @param [String] description Optional description of this flag.
    # @param default The value to use if no value for +name+ is given.
    # @param [Boolean] class_override If true, the +default+ can be overridden by a class-level method. See +get_value+.
    # @param handler The block to run in scope of the Bundle consuming it.
    # @return [Flag] The newly created flag.
    def make_flag(name, description: nil, default: nil, class_override: false, &handler)
      new_flag = Flag.new(name, description: description, default: default, class_override: class_override, &handler)
      @flag_objects ||= []
      @flag_objects << new_flag
      new_flag
    end

    # Contains instance-level methods for facilitating Flag processing.
    module InstanceMethods
      # Shortcut method to get the value this instance has for the given flag.
      # @param [Ladon::Flag] flag The flag to handle.
      # @return [Object] The value associated in this instance with the given flag.
      def get_flag_value(flag)
        flag.get_value(self)
      end

      # Shortcut method to make this instance leverage the given flag.
      # @param [Ladon::Flag] flag The flag to handle.
      def handle_flag(flag)
        flag.feed(self)
      end
    end
  end

  # Represents an external input that a Bundle expects. The flag pattern
  # should make it easier for us to identify these inputs, and quickly understand
  # the context around them.
  #
  # Flags can read values out of hashes.
  class Flag
    attr_reader :name, :description, :default, :class_override, :handler

    # Creates a new Flag.
    # NOTE: Every Flag is frozen upon instantiation - Flags are constants.
    #
    # @param [String|Symbol] name The name of this flag.
    # @param [String] description Optional description of this flag.
    # @param default The value to use if no value for +name+ is given.
    # @param [Boolean] class_override If true, the +default+ can be overridden by a class-level method. See +get_value+.
    # @param handler The block to run in scope of the Bundle consuming it.
    def initialize(name, description: nil, default: nil, class_override: false, &handler)
      @name = name
      @description = description
      @default = default
      @class_override = class_override
      @handler = handler
      self.freeze
    end

    # Feed the given +bundle+ by loading the value it has for this flag, defaulting if necessary,
    # then yielding the bundle and the value attained.
    #
    # @param [Ladon::Bundle] bundle A Bundle to load flag value from, which will also +instance_exec+ the +@handler+.
    def feed(bundle)
      raise BlockRequiredError, 'Cannot feed a bundle with a Flag that has no handler block!' if @handler.nil?
      bundle.instance_exec(get_value(bundle), &handler)
    end

    # Get the value for this flag from the given +bundle+.
    # If this flag has +class_override+ enabled, this method will automatically leverage the Bundle's Class to find a
    # conventional method matching the +@name+, with "default_" prepended. For example, if +@name+ is "url", your
    # class can define "default_url" to override the basic +@default+ associated with this flag.
    #
    # @param [Ladon::Bundle] bundle A Bundle to load flag value from. The Bundle's Class will also be used for the
    #   Class-level method for overriding the +@default+, if the method exists.
    # @return The value of this flag for the given +bundle+, or a default if no flag value is found.
    def get_value(bundle)
      default_to = @default
      default_method = "default_#{@name}"
      default_to = bundle.class.send(default_method) if @class_override && bundle.class.respond_to?(default_method)

      bundle.flags.fetch(@name, default_to)
    end

    # Create string-formatted representation of this Flag.
    # @return [String] describing flag details.
    def to_s
      [
        "Flag Name: #{name}",
        "Description: #{description}",
        "Default: #{default.nil? ? 'nil' : default}",
        "Class Can Override: #{class_override}",
        "Has Handler: #{!handler.nil?}"
      ].join("\n")
    end

    # Create Hash representation of this Flag.
    # @return [Hash] containing this flag's attributes.
    def to_h
      {
        name: name,
        description: description,
        default: default,
        class_override: class_override,
        handler: handler
      }
    end

    # Create a JSON-formatted version of result.
    # @return [String] containing flag attributes in a JSON format
    def to_json
      JSON.pretty_generate(to_h)
    end
  end
end
