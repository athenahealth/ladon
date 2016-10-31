require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe Graph do

      # unless otherwise redefined
      let(:start_state) { Class.new(State) }
      let(:config) { Ladon::Modeler::Config.new(start_state: start_state) }
      let(:graph) { Graph.new(config) }
      subject { graph }

      describe '#new' do
        subject { lambda { graph } }

        context 'when an invalid config is provided' do
          let(:config) { Object.new }

          it { is_expected.to raise_error(StandardError) }
        end

        context 'when a valid config is provided' do
          it { expect(subject.call).to be_a(Graph) }
        end
      end

      describe '#merge' do
        subject { lambda { graph.merge(target) } }

        context 'when the target is a different type than the subject' do
          let(:target) { Class.new(Graph).new(config) }

          it { is_expected.to raise_error(InvalidMergeError) }
        end

        context 'when the target is the same type as the subject' do
          let(:target) { Graph.new(config) }

          it { is_expected.not_to raise_error }

          context 'when the target has no states the subject does not' do
            let(:target) { Graph.new(config) }

            it { is_expected.not_to change(graph, :states) }
          end

          context 'when the target has states the subject does not' do
            let(:class2) { Class.new(State) }
            let(:config2) { Ladon::Modeler::Config.new(start_state: class2) }
            let(:target) { Graph.new(config2) }

            it { is_expected.to change(graph, :states).from(graph.states).to(graph.states | target.states)}
          end

          # TODO: transition merging test
          # TODO: context merging test
        end
      end

      describe '#state_count' do
        subject { graph.state_count }

        it { is_expected.to eq(graph.states.size)}
      end
    end
  end
end
