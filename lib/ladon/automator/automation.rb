module Ladon
  module Automator
    # Base class for Ladon automation. This class is exposed to encapsulate the
    # aspects of Automation not pertaining directly to operating through a model.
    #
    # @abstract
    class Automation < Bundle
      @is_abstract = true

      # Flag specifying how to format the Automation's +Result+ object.
      OUTPUT_FORMAT = make_flag(:output_format, default: nil) do |format_method|
        unless format_method.nil?
          assert('Automation result must respond to the formatting method') { result.respond_to?(format_method) }
        end
        @formatter = format_method
      end

      # Flag specifying where to write the formatted result (from OUTPUT_FORMAT flag.)
      # NOTE: if not specified and OUTPUT_FORMAT is given, will print to terminal.
      OUTPUT_FILE = make_flag(:output_file, default: nil) do |file_path|
        self.handle_flag(OUTPUT_FORMAT)

        if file_path.nil?
          next if @formatter.nil?

          sleep 1.0 # just so you have a chance to see previous print statements before the dump happens

          puts "\n"
          _print_separator_line('-', ' Target Results ')
          puts result.send(@formatter)
          _print_separator_line('-')
        else
          # if no format is available, try to infer from file extension, defaulting to :to_s
          if @formatter.nil?
            case File.extname(file_path)
              when '.json'
                @formatter = :to_json
              else
                @formatter = :to_s
            end
          end

          formatted_info = result.send(@formatter)
          results_written = assert('Must be able to open and write formatted result info to file path given') do
            File.write(File.expand_path(file_path), formatted_info) == formatted_info.length
          end

          # Use the class' name, defaulting to the superclass' name
          class_name = self.class.name || self.class.superclass.name
          puts "\t#{class_name} results written to #{File.expand_path(file_path)}" if results_written
        end
      end

      # Identifies the phases involved in this automation.
      # @return [Array<Phase>] Ordered array defining the Phases of this class of automation.
      def self.phases
        []
      end

      # Declares the class to be abstract. Ladon utilities will not attempt to execute Automations of any class that
      # returns true for this method.
      def self.abstract
        @is_abstract = true
      end

      # Ladon utilities will not attempt to execute Automations of any class that returns true for this method.
      # If false, the subclass is intended as a concrete, runnable Automation implementation.
      # Return false by default unless the subclass calls `.abstract` in the class definition.
      #
      # @return [Boolean] True if this class is abstract, false if not (e.g., is executable.)
      def self.abstract?
        !@is_abstract.nil? && @is_abstract == true
      end

      # Run the automation, executing each phase defined for the automation class in order.
      # @return [Ladon::Result] The result object for this Automation.
      def run
        raise MissingImplementationError, 'Cannot run an abstract automation!' if self.class.abstract?
        sandbox('Run') { self.class.phases.each { |phase| process_phase(phase) } }
        handle_output
        @result
      end

      # Determines if the specified phase is actually available to this automation.
      #
      # @param [Phase] phase The phase to check.
      # @return [Boolean] True if the automation defines the phase method, false otherwise.
      def phase_available?(phase)
        respond_to?(phase.name)
      end

      private

      # Run a phase of the Automation script, auto-timing the duration of its execution.
      # @param [Phase] phase The phase to process.
      def process_phase(phase)
        @logger.info("Processing phase: '#{phase.name}'")

        unless phase.valid_for?(self)
          @logger.warn("Phase validation failed; phase #{phase.name} skipped!")
          return
        end

        execute_phase(phase)
      end

      # Execute the specified phase. The phase will be sandboxed such that an unrescued error during the phase will not
      # crash the entire execution of this automation.
      # @param [Phase] phase The phase to execute.
      def execute_phase(phase)
        return on_phase_skipped(phase) unless phase_available?(phase)

        @timer.for(phase.name) do
          sandbox(phase.name) do # mark Automation a failure if a phase fails
            self.send(phase.name)
            @logger.info("#{phase.name} completed normally")
          end
        end
      end

      # Skip the specified phase.
      # @param [Phase] phase The phase to skip.
      def on_phase_skipped(phase)
        @logger.log("Skipping phase '#{phase.name}' because this automation has no such method.",
                    level: phase.required? ? Ladon::Logging::Level::ERROR : Ladon::Logging::Level::WARN)
        @result.failure if phase.required?
      end

      # Handle outputting the Result information.
      def handle_output
        self.handle_flag(Automation::OUTPUT_FILE)
      end
    end
  end
end
