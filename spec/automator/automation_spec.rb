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
              expect { automation.sandbox('name') { raise } }.to change { automation.result.error? }.from(false).to(true)
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
          let(:target_phase) { Phase.new(:example, validator: -> automation { !automation.nil? } ) }

          it 'executes the phase' do
            expect(automation).to receive(:execute_phase).with(target_phase)
            subject.call
          end
        end

        context 'when processing an invalid phase' do
          let(:target_phase) { Phase.new(:example, validator: -> automation { automation.nil? } ) }

          it 'does not execute the phase' do
            expect(automation).not_to receive(:execute_phase)
            subject.call
          end
        end
      end
    end
  end
end
