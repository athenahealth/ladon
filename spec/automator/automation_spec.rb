require 'spec_helper'
require 'ladon'

class ConcreteAutomation < Ladon::Automator::Automation
  PHASE_A = Ladon::Automator::Phase.new(:a, required: true)
  PHASE_B = Ladon::Automator::Phase.new(:b)

  def self.phases
    [PHASE_A, PHASE_B]
  end
end

class AbstractAutomation < ConcreteAutomation
  abstract
end

module Ladon
  module Automator
    is_windows = (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM)
    RSpec.describe Automation do
      describe '#new' do
        subject(:automation) { Automation.new(config: config) }

        context 'when given a valid config' do
          let(:config) { Ladon::Config.new }

          it 'raises no error' do
            expect { automation }.not_to raise_error
          end

          it { is_expected.to have_attributes(config: config) }

          it 'has a Result object' do
            expect(automation.result).to be_a(Ladon::Result)
          end

          it 'has a logger' do
            expect { automation.logger }.not_to raise_error
          end

          it 'has a timer' do
            expect { automation.timer }.not_to raise_error
          end

          it 'is marked abstract' do
            expect(automation.class.abstract?).to be true
          end
        end

        context 'when given an invalid config' do
          let(:config) { 5 }

          it 'raises an error' do
            expect { automation }.to raise_error(StandardError)
          end
        end
      end

      describe '#abstract?' do
        subject(:abstract_status) { automation_class.abstract? }

        context 'when automation is abstract' do
          let(:automation_class) { AbstractAutomation }

          it { is_expected.to be true }
        end

        context 'when automation is concrete' do
          let(:automation_class) { ConcreteAutomation }

          it { is_expected.to be false }
        end
      end

      describe '#sandbox' do
        subject(:automation) { Automation.new(config: Ladon::Config.new) }

        context 'when given a block' do
          context 'when the block does not raise' do
            it 'will not raise an error' do
              expect { automation.sandbox('name') {} }.not_to raise_error
            end

            it 'leaves the result status as success' do
              expect { automation.sandbox('name') {} }.not_to change { automation.result.success? }.from(true)
            end
          end

          context 'when the block raises' do
            it 'will call the on_error method' do
              expect(automation).to receive(:on_error)
              automation.sandbox('name') { raise }
            end

            it 'will not raise an error' do
              expect { automation.sandbox('name') {} }.not_to raise_error
            end

            it 'marks the Automation result as errored' do
              expect { automation.sandbox('name') { raise } }.to(
                change { automation.result.error? }.from(false).to(true)
              )
            end
          end
        end

        context 'when not given a block' do
          it 'raises an error' do
            expect { automation.sandbox('name') }.to raise_error(StandardError)
          end
        end
      end

      describe '#run' do
        let(:config) { Ladon::Config.new }
        let(:automation) { ConcreteAutomation.new(config: config) }
        subject { -> { automation.run } }

        it { is_expected.not_to raise_error }

        it 'processes each phase in the order they are defined' do
          expect(automation).to receive(:process_phase).with(ConcreteAutomation::PHASE_A)
          expect(automation).to receive(:process_phase).with(ConcreteAutomation::PHASE_B)
          subject.call
        end
      end

      describe '#process_phase' do
        let(:config) { Ladon::Config.new }
        let(:automation) { ConcreteAutomation.new(config: config) }
        let(:target_phase) { Phase.new(:a) }
        subject { -> { automation.send(:process_phase, target_phase) } }

        it 'validates the phase' do
          expect(target_phase).to receive(:valid_for?).with(automation)
          subject.call
        end

        context 'when processing a valid phase' do
          let(:target_phase) { Phase.new(:example, validator: ->(automation) { !automation.nil? }) }

          it 'executes the phase' do
            expect(automation).to receive(:execute_phase).with(target_phase)
            subject.call
          end
        end

        context 'when processing an invalid phase' do
          let(:target_phase) { Phase.new(:example, validator: ->(automation) { automation.nil? }) }

          it 'does not execute the phase' do
            expect(automation).not_to receive(:execute_phase)
            subject.call
          end
        end
      end

      describe '#handle_output' do
        let(:file_path) { !is_windows.nil? ? 'C:/some/file/path' : '/some/file/path' }
        let(:formatter) { :to_s }
        let(:automation) { ConcreteAutomation.spawn(flags: flags) }
        subject { -> { automation.handle_output } }

        before { allow(FileUtils).to receive(:mkdir_p) } # mock out making the obviously fake directories

        context 'when output file path is given' do
          context 'when output format flag is specified' do
            let(:flags) { { output_format: formatter, output_file: file_path } }
            it 'writes the selected format representation to the files at the given path' do
              expect(File).to receive(:write).with(file_path, automation.result.to_s)
              subject.call
            end
          end

          context 'when output format flag is not specified' do
            let(:flags) { { output_file: file_path } }
            context 'when file path has JSON extension' do
              let(:file_path) { !is_windows.nil? ? 'C:/some/file/path.json' : '/some/file/path.json' }
              it 'writes the JSON representation to the file at the given path' do
                expect(File).to receive(:write).with(file_path, automation.result.to_json)
                subject.call
              end
            end

            context 'when file path has xml extension' do
              let(:file_path) { !is_windows.nil? ? 'C:/some/file/path.xml' : '/some/file/path.xml' }
              it 'writes the JUnit representation to the file at the given path' do
                expect(File).to receive(:write).with(file_path, automation.result.to_junit)
                subject.call
              end
            end

            context 'when format cannot be determined from extension' do
              it 'writes the string representation to the files at the given path' do
                expect(File).to receive(:write).with(file_path, automation.result.to_s)
                subject.call
              end
            end
          end
        end

        context 'when output file path is not given' do
          context 'when output format flag is specified' do
            let(:flags) { { output_format: formatter } }

            it 'prints the formatted result data to STDOUT' do
              expect(STDOUT).to receive(:puts).with("\n")
              res_str = '-------------------------------- Target Results --------------------------------'
              expect(STDOUT).to receive(:puts).with(res_str)
              expect(STDOUT).to receive(:puts).with(automation.result.to_s)
              expect(STDOUT).to receive(:puts).with('-' * 80)
              subject.call
            end
          end

          context 'when output format flag is not specified' do
            let(:flags) { {} }

            it 'does not print result to terminal' do
              expect(STDOUT).not_to receive(:puts).with(automation.result.to_s)
            end

            it 'does not write result to file' do
              expect(File).not_to receive(:write)
            end
          end
        end
      end
    end
  end
end
