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
      OUTPUT_FILES = make_flag(:output_files, default: nil) do |file_path_list|
        self.handle_flag(OUTPUT_FORMAT)

        if file_path_list.nil?
          next if @formatter.nil?

          puts "\n"
          _print_separator_line('-', ' Target Results ')
          puts result.send(@formatter)
          _print_separator_line('-')
        else
          file_path_list.each do |file_path|
            # if no format is available, try to infer from file extension, defaulting to :to_s
            self.send(:detect_output_format, file_path)

            results_written = assert('Must be able to open and write formatted result info to file path given') do
              output_file = File.expand_path(file_path)
              # If the directory the file is going to doesn't exist (likely common), create it now
              dirname = File.dirname(output_file)
              FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

              formatted_info = result.send(@formatter)
              File.write(output_file, formatted_info) == formatted_info.length
            end

            # Use the class' name, defaulting to the superclass' name
            class_name = self.class.name || self.class.superclass.name
            puts "\t#{class_name} results written to #{File.expand_path(file_path)}" if results_written
          end
        end
      end

      # If given a truthy value, "Ladon puts" (+lputs+)
      SUPPRESS_STDOUT = make_flag(:suppress_stdout, default: false) { |suppress| @suppress = suppress }

      # Method that stores the subclass when loaded to find the leaf automation class
      def self.inherited(subclass)
        @@leaf_automation_class = subclass
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
        self.handle_flag(SUPPRESS_STDOUT)
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

      # Handle outputting the Result information.
      def handle_output
        self.handle_flag(Automation::OUTPUT_FILES)
      end

      # Simple wrapper around +Kernel::puts+ that will be supressed if the SURPRESS_STDOUT flag is truthy.
      # @param msg The thing to puts to STDOUT.
      def puts(msg)
        super(msg) unless @suppress
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

      # Print a separator line string.
      def _print_separator_line(sep = '*', title = '')
        line_len = 80
        half_width = (line_len - title.to_s.length) / 2.0
        puts sep.to_s * half_width.floor + title.to_s + sep.to_s * half_width.ceil
      end

      # Given the +file_path+, default this automation's +formatter+ to the appropriate serializer method
      # based on file extension. Defaults to +to_s+.
      # @param [String] file_path The path to which the formatted Result will be written.
      def detect_output_format(file_path)
        @formatter ||= case File.extname(file_path)
                       when '.json'
                         :to_json
                       when '.xml'
                         :to_junit
                       else
                         :to_s
                       end
      end
    end
  end
end
