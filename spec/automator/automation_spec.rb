require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    RSpec.describe Automation do

      describe '#new' do
        subject(:automation) { Automation.new(config) }

        context 'when given a valid config' do
          let(:config) { Ladon::Automator::Config.new }

          it 'raises no error' do
            expect{automation}.not_to raise_error
          end

          it { is_expected.to have_attributes(config: config) }

          it 'has a Result object' do
            expect(automation.result).to be_a(Ladon::Automator::Result)
          end

          it 'has a private logger' do
            expect{automation.logger}.to raise_error(NoMethodError)
            expect(automation.instance_variable_get('@logger')).to be_a(Ladon::Automator::Logging::Logger)
          end

          it 'has a private timer' do
            expect{automation.timer}.to raise_error(NoMethodError)
            expect(automation.instance_variable_get('@timer')).to be_a(Ladon::Automator::Timing::Timer)
          end

          it 'is marked abstract' do
            expect(automation.class.abstract?).to be true
          end
        end

        context 'when given an invalid config' do
          let(:config) { 5 }

          it 'raises an error' do
            expect{automation}.to raise_error(StandardError)
          end
        end
      end

      describe '#abstract?' do
        subject(:abstract_status) { Automation.abstract? }

        it { is_expected.to be true }
      end

      describe '#sandbox' do
        subject(:automation) { Automation.new(Ladon::Automator::Config.new) }

        context 'when given a block' do
          context 'when the block does not raise' do
            it 'will not raise an error' do
              expect{automation.sandbox('name') {}}.not_to raise_error
            end

            it 'leaves the result status as success' do
              expect{automation.sandbox('name') {} }.not_to change{automation.result.success?}.from(true)
            end
          end

          context 'when the block raises' do
            it 'will call the on_error method' do
              expect(automation).to receive(:on_error)
              automation.sandbox('name') { raise }
            end

            it 'will not raise an error' do
              expect{automation.sandbox('name') {}}.not_to raise_error
            end

            it 'marks the Automation result as errored' do
              expect{automation.sandbox('name') { raise } }.to change{automation.result.error?}.from(false).to(true)
            end
          end
        end

        context 'when not given a block' do
          it 'raises an error' do
            expect{automation.sandbox('name')}.to raise_error(StandardError)
          end
        end
      end

      describe '#run' do
        let(:config) { Ladon::Automator::Config.new }
        subject(:automation) { Automation.new(config) }

        context 'when a required phase is not defined for the Automation' do
          it 'raises an error' do
            expect{automation.run}.to raise_error(StandardError)
          end
        end

        context 'when the Automation has its required phases defined' do
          let(:phased_class) do
            Class.new(Automation) do
              Automation.required_phases.each { |phase| define_method(phase.to_sym) {} }
              Automation.all_phases.each { |phase| define_method(phase.to_sym) {} }
            end
          end

          subject(:automation) { phased_class.new(Ladon::Automator::Config.new) }

          it 'calls the defined phases of the automation, in order' do
            phased_class.all_phases.each do |phase|
              expect(automation).to receive(:do_phase).with(phase, any_args).ordered
            end
            automation.run
          end

          it 'calls the required phases' do
            phased_class.required_phases.each { |phase| expect(subject).to receive(phase) }
            automation.run
          end

          context 'when a to_index is specified' do
            it 'runs from the next scheduled phase through the phase at the specified index' do
              phased_class.all_phases.each_with_index do |phase, idx|
                expect(automation).to receive(phase)
                expect{automation.run(to_index: idx)}.to change(automation, :phase).by(1)
              end
            end
          end
        end
      end
    end

    RSpec.describe ModelAutomation do
      describe '#new' do
        subject(:automation) { ModelAutomation.new(Ladon::Automator::Config.new) }

        context 'when class has a target_model defined' do
          before do
            allow(ModelAutomation).to receive(:target_model).and_return(model_value)
          end

          context 'when the target_model returns a Ladon Modeler FSM' do
            let(:model_value) do
              Ladon::Modeler::FiniteStateMachine.new
            end

            it 'does not raise an error' do
              expect{automation}.not_to raise_error
            end
          end

          context 'when the target_model returns something other than a Ladon Modeler FSM' do
            let(:model_value) { nil }

            it 'raises an error' do
              expect{automation}.to raise_error(StandardError)
            end
          end
        end

        context 'when class has no target model defined' do
          it 'raises an error' do
            expect{automation}.to raise_error(StandardError)
          end
        end
      end
    end
  end
end
