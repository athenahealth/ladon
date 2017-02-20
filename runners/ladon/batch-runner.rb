require 'pathname'
require 'pp'
require 'pry'
require 'json'
require 'fileutils'
require 'ladon/automator'
require 'ladon/automation-runner'

# Simple Automation that triggers a batch of ladon-runs as spec-ed by a simple JSON config.
class LadonBatchRunner < Ladon::Automator::Automation
  FLAG_SETS_KEY = :flag_sets
  # Key that individual automation configs can be found at
  AUTOMATION_CONFIG_KEY = :automation_configs

  # Flag specifying the name to give this batch
  BATCH_NAME = make_flag(:batch_name, default: nil) do |batch_name|
    @batch_name = batch_name
    halting_assert('Batch name must be given') { !(batch_name.nil? || batch_name.empty?) }
  end

  # Flag that handles loading the target automation Ruby script.
  CONFIG_FILE_PATH = make_flag(:config_file, default: nil) do |config_path|
    halting_assert('Config path must point to an existing file') do
      config_path = File.expand_path(config_path)
      File.file?(config_path)
    end

    halting_assert('Must be able to read and parse a valid-looking config file') do
      @config = JSON.parse(File.read(config_path), symbolize_names: true)
      @config[AUTOMATION_CONFIG_KEY].is_a?(Array)
    end
  end

  # Delay period between triggering the run of individual Automation runs in this batch.
  RUN_DELAY = make_flag(:run_delay, default: 0.5) { |delay| sleep(delay) if delay.is_a?(Numeric) && delay > 0 }

  # Ladon-batch uses a setup-execute-teardown cycle.
  # If setup results in a non-success status, execute is skipped but teardown will still occur.
  def self.phases
    [
        Ladon::Automator::Phase.new(:setup, required: true),
        Ladon::Automator::Phase.new(:build, required: true, validator: -> automation { automation.result.success? }),
        Ladon::Automator::Phase.new(:execute, required: true, validator: -> automation { automation.result.success? }),
        Ladon::Automator::Phase.new(:teardown, required: true)
    ]
  end

  # During setup, ladon-batch reads the config file and prepares to run the specified
  # It then uses that information to load the target Automation class it will run.
  def setup
    puts "\nSetting up ladon-batch..."
    _print_separator_line

    self.handle_flag(BATCH_NAME)
    self.handle_flag(CONFIG_FILE_PATH)

    puts 'Error processing config file; batch will not be executed.' unless result.success?
  end

  # During build, ladon-batch builds the flags necessary to spawn +ladon-run+s for each configuration detected.
  def build
    puts "\nExecuting ladon-batch"
    _print_separator_line

    @runners = []

    # TODO: figure out wildcarding in TARGET_AUTOMATION_PATH.
    # Maybe we can preprocess AUTOMATION_CONFIG_KEY, using Dir to detect multiples, and expanding the config
    # with any repeats. Maybe we detect all non-abstract subclasses of automation_config[:automation_name] ?
    # Not sure yet. We'll get to this later.

    @config[AUTOMATION_CONFIG_KEY].each do |automation_config|
      # build basic flags for LadonAutomationRunner
      runner_flags = {
          LadonAutomationRunner::TARGET_AUTOMATION_PATH.name => File.expand_path(automation_config[:automation_path]),
          LadonAutomationRunner::TARGET_AUTOMATION_CLASS_NAME.name => automation_config[:automation_name],
          Ladon::Automator::Automation::SUPPRESS_STDOUT.name => true # suppress STDOUT in auto runners
      }

      # process this config's flag_sets
      my_flags = automation_config.fetch(:flags, {})
      target_flag_sets = automation_config.fetch(FLAG_SETS_KEY, [])
      if target_flag_sets.is_a?(Array) && !target_flag_sets.empty?
        # create hash of set_name => merge of that set INTO the explicit flags for this automation
        target_flag_sets.map! { |set_name| [ set_name, my_flags.merge(@config[FLAG_SETS_KEY][set_name.to_sym]) ] }.to_h
      else
        # no flag sets, so we just have one set of flags -- the explicit flags configured for this automation
        target_flag_sets = { flags: my_flags }
      end

      repeats = automation_config[:instances]
      repeats = 1 if repeats.nil? || !repeats.is_a?(Fixnum) || repeats < 0
      target_flag_sets.each do |set_name, flag_set|
        repeats.times.each do |instance|
          instance_flags = flag_set.dup
          file_pattern = @config[:output_file]
          unless file_pattern.nil? || file_pattern.empty?
            file_path = @config[:output_file] % {batch_name: @batch_name, set_name: set_name, instance: instance + 1}
            instance_flags[Ladon::Automator::Automation::OUTPUT_FILE.name] = File.expand_path(file_path)
          end

          spawn_flags = runner_flags.dup
          spawn_flags[LadonAutomationRunner::TARGET_AUTOMATION_FLAGS.name] = instance_flags
          @runners << LadonAutomationRunner.spawn(flags: spawn_flags)
        end
      end
    end
  end

  # During execute, ladon-batch runs the runners compiled during +build+.
  def execute
    threads = []
    @runners.each_with_index do |runner, idx|
      threads << Thread.new { sandbox("Execute runner ##{idx}") { runner.run } }
      self.handle_flag(RUN_DELAY)
    end
    threads.each(&:join)
  end

  # Simple teardown function.
  def teardown
    puts "\nWrapping up ladon-batch..."
    @runners.group_by { |r| r.result.status }.each { |status, results| result.record_data(status, results.size) }
    assert('All Automations in the batch should succeed') do
      @runners.all? { |r| r.result.success? }
    end
  end
end