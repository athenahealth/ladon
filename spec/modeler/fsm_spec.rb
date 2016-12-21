require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe FiniteStateMachine do
      # unless otherwise redefined
      let(:start_state) { Class.new(State) }
      let(:fsm) { FiniteStateMachine.new }
      subject { fsm }

      describe '#new' do
        context 'when a valid config is provided' do
          it { is_expected.to be_a(FiniteStateMachine) }
        end
      end

      describe '#use_state_type' do
        subject { -> { fsm.use_state_type(target_state) } }

        context 'when the specified state is known to the graph' do
          let(:target_state) { start_state }

          it { is_expected.not_to raise_error }
          it { is_expected.to change(fsm, :current_state).to(an_instance_of(target_state)) }
        end

        context 'when the specified state is not known to the graph' do
          let(:target_state) { Class.new(State) }

          it { is_expected.not_to raise_error }
          it { is_expected.to change { fsm.state_loaded?(target_state) }.from(false).to(true) }
          it { is_expected.to change(fsm, :current_state).to(an_instance_of(target_state)) }
        end
      end

      describe '#selection_strategy' do
        subject { -> { fsm.selection_strategy([]) } }

        it { is_expected.to raise_error(Ladon::MissingImplementationError) }
      end

      describe '#passes_prefilter' do
        subject { fsm.passes_prefilter?('anything') }

        it { is_expected.to be true }
      end

      describe '#make_transition' do
        subject { -> { fsm.make_transition } }

        context 'when machine has no current state' do
          it { is_expected.to raise_error(NoCurrentStateError) }
        end

        context 'when machine has a current state' do
          before { fsm.use_state_type(start_state) }

          context 'when transitions are not loaded for the current state' do
            context 'when selection_strategy is not defined' do
              it 'makes the FSM load transitions defined for the current state type, and later raises when calling the missing selection_strategy' do
                expect(fsm).to receive(:load_transitions).with(start_state.class, strategy: LoadStrategy::LAZY)
                expect{subject.call}.to raise_error(Ladon::MissingImplementationError, '#selection_strategy')
              end
            end

            context 'when selection_strategy is defined' do
              it 'tells the FSM load the transitions defined for the current state type, succeeds in running the selection_strategy, and calls #execute_transition' do
                allow(fsm).to receive(:selection_strategy).and_return(Ladon::Modeler::Transition.new)
                expect(fsm).to receive(:load_transitions).with(start_state.class, strategy: LoadStrategy::LAZY)
                expect(fsm).to receive(:execute_transition)

                expect{subject.call}.not_to raise_error
              end
            end
          end

          context 'when transitions are already loaded for the current state' do
            before { fsm.add_transitions(start_state, []) }

            context 'when selection_strategy is not defined' do
              it 'does not tell the FSM to perform any transition load operation, and later raises when calling the missing selection_strategy' do
                expect(fsm).to receive(:make_transition).and_call_original.ordered
                expect(fsm).not_to receive(:load_transitions).ordered
                expect{subject.call}.to raise_error(Ladon::MissingImplementationError, '#selection_strategy')
              end
            end

            context 'when selection_strategy is defined' do
              it 'does not tell the FSM to perform any transition load operation, and later raises when calling the missing selection_strategy' do
                allow(fsm).to receive(:selection_strategy).and_return(Ladon::Modeler::Transition.new)
                expect(fsm).not_to receive(:load_transitions).ordered
                expect(fsm).to receive(:execute_transition)

                expect{subject.call}.not_to raise_error
              end
            end
          end
        end
      end

      describe '#execute_transition' do
        subject { -> { fsm.execute_transition(transition) } }

        context 'when transition is a Ladon::Modeler::Transition instance' do
          let(:target_state) { Class.new(State) }
          let(:transition) do
            Transition.new do |t|
              t.target_loader { }
              t.target_identifier { target_state }
              t.by { |current_state|  }
            end
          end

          before { fsm.use_state_type(start_state) }

          it 'calls the execute method of the transition' do
            expect(transition).to receive(:execute)
            subject.call
          end

          it "updates the FSM's current_state to an instance of the target's type" do
            expect{subject.call}.to change(fsm, :current_state).to instance_of(target_state)
          end

          context 'when target is able to verify current state' do
            it { is_expected.not_to raise_error }
          end

          context 'when target is NOT able to verify current state' do
            let(:target_state) do
              Class.new(State) do
                def verify_as_current_state?
                  false
                end
              end
            end

            it { is_expected.to raise_error(TransitionFailedError) }
          end
        end

        context 'when transition is not a Ladon::Modeler::Transition instance' do
          let(:transition) { Object.new }

          it { is_expected.to raise_error(ArgumentError) }
        end
      end

      describe '#prefiltered_transitions' do
        let(:key) { 'key' }
        let(:wanted_value) { 123 }
        let(:unwanted_value) { 456 }
        let(:wanted_transition) { Transition.new { |t| t.meta(key, wanted_value) } }
        let(:unwanted_transition) { Transition.new { |t| t.meta(key, unwanted_value) } }
        let(:transitions) do
          [
            wanted_transition,
            unwanted_transition
          ]
        end

        context 'when given a block' do
          let(:block_behavior) { ->(t) { t.meta_for(key) == wanted_value } }
          subject { fsm.prefiltered_transitions(transitions) { |t| block_behavior.call(t) } }

          it { is_expected.to include(wanted_transition) }
          it { is_expected.not_to include(unwanted_transition) }
        end

        context 'when not given a block' do
          subject { fsm.prefiltered_transitions(transitions) }

          # should apply default +passes_prefilter?+, which returns true for all transitions
          it { is_expected.to include(unwanted_transition, wanted_transition) }
        end
      end

      describe '#valid_transitions' do
        subject { fsm.valid_transitions(transition_options) }

        before { allow(fsm).to receive(:current_state).and_return(current_state) }

        context 'when the fsm has no current state' do
          let(:current_state) { nil }
          let(:transition_options) { [] }

          it 'raises an error' do
            expect { subject }.to raise_error(StandardError)
          end
        end

        context 'when the fsm has a current state' do
          let(:valid_transition) { Transition.new { |t| t.when { |current| current.instance_variable_get('@example') == 5 } } }
          let(:invalid_transition) { Transition.new { |t| t.when { |current| current.instance_variable_get('@example') == 6 } } }
          let(:transition_options) { [valid_transition, invalid_transition] }
          let(:current_state) do
            state = Class.new(State).new
            state.instance_variable_set('@example', 5)
            state
          end

          it 'does not raise an error' do
            expect { subject }.not_to raise_error
          end

          it { is_expected.to be_an_instance_of(Array) }
          it { is_expected.to include(valid_transition) }
          it { is_expected.not_to include(invalid_transition) }
        end
      end

      describe '#current_state' do
        context 'when machine has a current state' do
          before { fsm.use_state_type(start_state) }

          context 'when not given a block' do
            subject { fsm.current_state }

            it 'returns the current state of the machine' do
              expect(subject).to be_an_instance_of(start_state)
            end
          end

          context 'when given a block' do
            subject { fsm.current_state { |current_state| current_state } }

            it 'returns the value of calling the block with the current state' do
              expect(subject).to be_an_instance_of(start_state)
            end
          end
        end

        context 'when machine has no current state' do
          context 'when not given a block' do
            subject { fsm.current_state }

            it 'returns the current state of the machine' do
              expect(subject).to be_nil
            end
          end

          context 'when given a block' do
            subject { fsm.current_state { |current_state| current_state } }

            it 'returns the value of calling the block with the current state' do
              expect(subject).to be_nil
            end
          end
        end
      end
    end
  end
end
