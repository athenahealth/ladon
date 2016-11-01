require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe FiniteStateMachine do

      # unless otherwise redefined
      let(:start_state) { Class.new(State) }
      let(:config) { Ladon::Modeler::Config.new(start_state: start_state) }
      let(:fsm) { FiniteStateMachine.new(config) }
      subject { fsm }

      describe '#new' do
        context 'when a valid config is provided' do
          it { is_expected.to be_a(FiniteStateMachine) }

          it { is_expected.to have_attributes(current_state: an_instance_of(start_state)) }
        end
      end

      describe '#use_state' do
        subject { lambda { fsm.use_state(target_state) } }

        context 'when the specified state is known to the graph' do
          let(:target_state) { start_state }

          it { is_expected.not_to raise_error }
          it { is_expected.to change(fsm, :current_state).to(an_instance_of(target_state)) }
        end

        context 'when the specified state is not known to the graph' do
          let(:target_state) { Class.new(State) }

          it { is_expected.to change{fsm.state_loaded?(target_state)}.from(false).to(true)}
          #it { is_expected.to raise_error(StandardError, "No known state #{target_state}!") }
        end
      end

      describe '#selection_strategy' do
        subject { lambda { fsm.selection_strategy([]) } }

        it { is_expected.to raise_error(Ladon::MissingImplementationError) }
      end

      describe '#passes_prefilter' do
        subject { fsm.passes_prefilter?('anything') }

        it { is_expected.to be true }
      end

      describe '#make_transition' do

      end

      describe '#prefiltered_transitions' do

      end

      describe '#valid_transitions' do
        subject { fsm.valid_transitions(transition_options) }

        before { allow(fsm).to receive(:current_state).and_return(current_state) }

        context 'when the fsm has no current state' do
          let(:current_state) { nil }
          let(:transition_options) { [] }

          it 'raises an error' do
            expect{subject}.to raise_error(StandardError)
          end
          #it { is_expected.to raise_error(StandardError) }
        end

        context 'when the fsm has a current state' do
          let(:valid_transition) { Transition.new { |t| t.when { |current| current.instance_variable_get('@example') == 5} } }
          let(:invalid_transition) { Transition.new { |t| t.when { |current| current.instance_variable_get('@example') == 6} } }
          let(:transition_options) { [valid_transition, invalid_transition] }
          let(:current_state) do
            state = Class.new(State).new({})
            state.instance_variable_set('@example', 5)
            state
          end

          it 'does not raise an error' do
            expect{subject}.not_to raise_error
          end

          it { is_expected.to be_an_instance_of(Array) }
          it { is_expected.to include(valid_transition) }
          it { is_expected.not_to include(invalid_transition) }
        end
      end
    end
  end
end
