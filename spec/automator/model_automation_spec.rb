require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    RSpec.describe ModelAutomation do
      let(:automation_class) { ModelAutomation }
      let(:automation) { automation_class.spawn }

      describe '#verify_model' do
        subject { -> { automation.verify_model } }

        context 'when build_model does not create the model attribute as a FSM' do
          before { automation.build_model }

          it { is_expected.to raise_error(StandardError) }
        end

        context 'when build_model creates the model attribute as a FSM' do
          let(:automation_class) do
            Class.new(ModelAutomation) do
              def build_model
                self.model = Ladon::Modeler::FiniteStateMachine.new
              end
            end
          end

          before { automation.build_model }

          it { is_expected.not_to raise_error }
        end
      end

      describe '#run' do
        subject { -> { automation.run } }

        context 'when execute is not defined' do
          it { is_expected.to raise_error(StandardError) }
        end

        context 'when execute method is defined' do
          let(:automation_class) do
            Class.new(ModelAutomation) do
              def setup; end
              def execute; end
              def teardown; end
            end
          end

          context 'when verify_model returns a Ladon FSM' do
            before { automation.model = Ladon::Modeler::FiniteStateMachine.new }

            it 'skips no phases' do
              expect(automation).to receive(:build_model).ordered
              expect(automation).to receive(:verify_model).ordered
              expect(automation).to receive(:setup).ordered
              expect(automation).to receive(:execute).ordered
              expect(automation).to receive(:teardown).ordered

              subject.call # run the automation and check outcomes
            end
          end

          context 'when verify_model does not return a Ladon FSM' do
            it 'skips all phases after verify_model' do
              expect(automation).to receive(:build_model).ordered
              expect(automation).to receive(:verify_model).ordered

              expect(automation).not_to receive(:setup)
              expect(automation).not_to receive(:execute)
              expect(automation).not_to receive(:teardown)

              subject.call # run the automation and check outcomes
            end
          end
        end
      end
    end
  end
end
