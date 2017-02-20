require 'pathname'
require 'pp'
require 'pry'
require 'ladon/automator'

# Automation that facilitates running Ladon Automation scripts.
class LadonAutomationRunner < Ladon::Automator::Automation
  # Conventional name for a directory containing Ladon automations;
  # If found as an ancestor in the TARGET_AUTOMATION_PATH, this directory will be added to the load path.
  AUTOMATION_DIR_BASENAME = 'automations'.freeze

  # Flag that handles loading the target automation Ruby script.
  TARGET_AUTOMATION_PATH = make_flag(:target_path, default: nil) do |auto_path|
    halting_assert('Automation path must point to an existing file') do
      auto_path = File.expand_path(auto_path)
      File.file?(auto_path)
    end

    halting_assert('Configures the load path and loads the target automation without error') do
      _include_load_path(auto_path)
      require_relative auto_path
      true
    end
  end

  # Flag to identify the target Automation Class
  TARGET_AUTOMATION_CLASS_NAME = make_flag(:target_class_name, default: nil) do |name|
    @target_automation_class = nil

    if name.nil? || name.empty?
      # Detect all Automation subclasses
      detected_automations = ObjectSpace.each_object(Ladon::Automator::Automation.singleton_class)

      # Filter to only those Automation subclasses that are marked executable
      executable_automations = detected_automations.reject { |cls| cls.abstract? || cls <= LadonAutomationRunner}
      halting_assert('Must detect a single non-abstract automation') { executable_automations.size == 1 }
      @target_automation_class = executable_automations[0]
    else
      @target_automation_class = Object.const_get(name)
    end

    halting_assert('Target Automation class must be a subclass of Ladon::Automator::Automation') do
      @target_automation_class < Ladon::Automator::Automation
    end
  end

  # Flag that can modify the target Automation so that interactive mode is triggered before various phases.
  INTERACTIVE_PHASES = make_flag(:interactive_phases, default: []) do |phase_names|
    halting_assert('Interactive phases must be an array') { phase_names.is_a?(Array) }

    # To facilitate interactive mode, we create a magic subclass of the target type.
    # On this subclass, we redefine the methods that have been specified for interactive mode with a
    # hook to start a pry session. The immediate next call is a +super()+ so you can easily "step" into the
    # target method. There is probably a better way to do this, but I haven't come up with it yet.
    wrapper = Class.new(@target_automation_class) do
      def self.make_phases_interactive(phase_names)
        phase_names.uniq.each do |name|
          next unless method_defined?(name) # avoid incidentally implementing a missing phase

          define_method name do
            binding.pry
            super()
          end
        end
      end
    end

    wrapper.make_phases_interactive(phase_names)
    @target_automation = wrapper.spawn(flags: self.get_flag_value(TARGET_AUTOMATION_FLAGS))
  end

  # Flag containing the Flags to pass to the target Automation.
  TARGET_AUTOMATION_FLAGS = make_flag(:target_flags, default: {})

  # Flag to use to trigger interactive mode after the target Automation finishes executing.
  PRY = make_flag(:pry, default: false) { |activate| self.pry if activate }

  # Ladon-run uses a setup-execute-teardown cycle.
  # If setup results in a non-success status, execute is skipped but teardown will still occur.
  def self.phases
    [
        Ladon::Automator::Phase.new(:setup, required: true),
        Ladon::Automator::Phase.new(:execute, required: true, validator: -> automation { automation.result.success? }),
        Ladon::Automator::Phase.new(:teardown, required: true)
    ]
  end

  # During setup, ladon-run parses and validates the invocation options it was given.
  # It then uses that information to load the target Automation class it will run.
  def setup
    puts "\nSetting up ladon-run..."
    _print_separator_line

    self.handle_flag(TARGET_AUTOMATION_PATH)
    self.handle_flag(TARGET_AUTOMATION_CLASS_NAME)
    self.handle_flag(INTERACTIVE_PHASES)

    puts 'A problem occurred; the target automation will not be executed.' unless result.success?
  end

  # During execute, ladon-run prepares the functionality of the -i flag, spawns the
  # target Automation instance, and runs it.
  def execute
    puts "\nExecuting ladon-run of: #{@target_automation_class.name}"
    _print_separator_line

    halting_assert('Target automation must run successfully') do
      @target_automation.run
      @target_automation.result.success?
    end
  end

  # Teardown occurs once the target Automation instance stops running.
  # If the -p/--pry option was given, you will enter interactive mode here.
  #
  # This will also handle formatting and outputting the Automation's Result,
  # if the appropriate options were specified.
  def teardown
    puts "\nWrapping up ladon-run..."
    _print_separator_line

    self.handle_flag(PRY)
  end

  private

  # Look for a conventional directory to add to the load path. This runner
  # assumes a directory structure in which all automations are located under a
  # single directory with a conventional name at the root of another directory
  # that contains all other files required for the automation to run.
  # Specifically, it is looking for a directory with the following structure:
  #
  # <project_dir>/ (this is what gets added to the load path)
  #   AUTOMATION_DIR_BASENAME/
  #     ... (the automation being run is somewhere in here)
  #   ... (any other directories and files)
  #
  # If found, the directory is added to the load path.
  def _include_load_path(automation_path)
    Pathname.new(automation_path).ascend do |path|
      if path.basename.to_s.eql?(AUTOMATION_DIR_BASENAME)
        $LOAD_PATH.unshift(path.dirname.to_s)
        break
      end
    end
  end
end