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
        context 'when the target is a different type than the subject' do
          let(:target) { Class.new(Graph).new(config) }

          it 'will raise an invalid merge error' do
            expect {graph.merge(target)}.to raise_error(InvalidMergeError)
          end
        end

        context 'when the target is the same type as the subject' do
          let(:target) { Graph.new(config) }

          it 'will not raise an error' do
            expect {graph.merge(target)}.not_to raise_error
          end

          context 'when the target has no states the subject does not' do
            let(:target) { Graph.new(config) }

            it 'adds the states from the target to the subject'  do
              expect {graph.merge(target)}.not_to change{graph.states}
            end
          end

          context 'when the target has states the subject does not' do
            let(:class2) { Class.new(State) }
            let(:config2) { Ladon::Modeler::Config.new(start_state: class2) }
            let(:target) { Graph.new(config2) }

            it 'adds the states from the target to the subject'  do
              expect {graph.merge(target)}.to change{graph.states}.from(graph.states).to(graph.states | target.states)
            end
          end

          # TODO: transition merging test
          # TODO: context merging test
        end
      end
    end
  end
end
