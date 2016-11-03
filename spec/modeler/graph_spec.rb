require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe Graph do

      # unless otherwise redefined
      let(:start_state) { Class.new(State) }
      let(:graph) { Graph.new }
      subject { graph }

      describe '#new' do
        subject { lambda { graph } }

        it { expect(subject.call).to be_a(Graph) }
      end

      describe '#merge' do
        subject { lambda { graph.merge(target) } }

        context 'when the target is a different type than the subject' do
          let(:target) { Class.new(Graph).new }

          it { is_expected.to raise_error(InvalidMergeError) }
        end

        context 'when the target is the same type as the subject' do
          let(:target) { Graph.new }

          it { is_expected.not_to raise_error }

          context 'when the target has no states the subject does not' do
            let(:target) { Graph.new }

            it { is_expected.not_to change(graph, :states) }
          end

          context 'when the target has states the subject does not' do
            let(:class2) { Class.new(State) }
            let(:target) { Graph.new }

            before do
              graph.load_state_type(start_state)
              target.load_state_type(class2)
            end

            it { is_expected.to change(graph, :states).from(Set.new([start_state])).to(Set.new([start_state, class2])) }
          end

          # TODO: transition merging test
          # TODO: context merging test
        end
      end

      describe '#state_count' do
        subject { graph.state_count }

        it { is_expected.to eq(graph.states.size)}
      end

      describe 'transition methods' do
        let(:target_state) { Class.new(State) }
        let(:start_state) { Class.new(State) }
        let(:transitions) do
          [
              Transition.new do |t|
                t.to_load_target_state_type { }
                t.to_identify_target_state_type { target_state }
              end
          ]
        end

        before do
          allow(start_state).to receive(:transitions).and_return(transitions)
          allow(target_state).to receive(:transitions).and_return([])
        end

        describe '#load_transitions' do

        end

        describe '#add_transitions' do

        end

        describe '#transitions_loaded?' do
          context 'when the given state has been loaded' do
            subject { graph.transitions_loaded?(start_state) }

            before { graph.load_state_type(start_state, strategy: Ladon::Modeler::LoadStrategy::CONNECTED) }
            it { is_expected.to be true }
          end

          context 'when the given state has not been loaded' do
            subject { graph.transitions_loaded?(Class.new) }
            it { is_expected.to be false }
          end
        end

        describe '#transition_count_for' do
          let(:loaded_state) { Class.new(State) }
          let(:transitions) { [Transition.new, Transition.new] }

          subject { graph.transition_count_for(state_class) }

          before do
            allow(loaded_state).to receive(:transitions).and_return(transitions)
            graph.load_state_type(loaded_state, strategy: Ladon::Modeler::LoadStrategy::CONNECTED)
          end

          context 'when the state class has been loaded' do
            let(:state_class) { loaded_state }
            it { is_expected.to eq(transitions.size) }
          end

          context 'when the state class has not been loaded' do
            let(:state_class) { Class.new(State) }

            it { is_expected.to eq(0) }
          end
        end
      end
    end
  end
end
