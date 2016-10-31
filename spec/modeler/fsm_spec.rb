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

          it { is_expected.to raise_error(StandardError, "No known state #{target_state}!") }
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

      end
    end
  end
end
