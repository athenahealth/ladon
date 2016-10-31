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

=begin
      describe 'when working with an existing finite state machine' do

        describe 'when the machine has no states loaded' do
          it 'correctly reports state configuration' do
            expect(@fsm.states).to be_empty
            expect(@fsm.state_count).to eq(0)
            expect(@fsm.state_loaded?(Object)).to be false
          end

          it 'has no transition keys' do
            expect(@fsm.transitions.keys.empty?).to be true
          end
        end

        describe 'when loading states into the machine' do
          it 'does not let you load anything other than a Class as a state' do
            expect {@fsm.load_state_type(Class.new(State))}.not_to raise_error
            [1, 2.2, :symbol, '', {}, []].each do |ex|
              expect{@fsm.load_state_type(ex)}.to raise_error(InvalidStateTypeError, ex.to_s)
            end
          end

          it 'will load multiple states' do
            newtype = Class.new(State)
            @fsm.load_state_type(newtype)
            expect(@fsm.state_count).to eq(1)
            expect(@fsm.states).to eq(Set.new([newtype]))

            newtype2 = Class.new(State)
            @fsm.load_state_type(newtype2)
            expect(@fsm.state_count).to eq(2)
            expect(@fsm.states).to eq(Set.new([newtype, newtype2]))
          end

          it 'does not change when loading an already known state' do
            newtype = Class.new(State)
            expect {@fsm.load_state_type(newtype)}.to change {@fsm.state_count}.from(0).to(1)
            expect {@fsm.load_state_type(newtype)}.not_to change {@fsm.state_count}.from(1)
          end
        end

        describe 'when the machine has at least one state' do
          before do
            newtype = Class.new(State)
            newtype2 = Class.new(State)
            @states = Set.new([newtype, newtype2])
            @states.each {|state_cls| @fsm.load_state_type(state_cls)}
          end

          describe '#state_count' do
            it 'correctly reports the number of states' do
              expect(@fsm.state_count).to eq(@states.size)
            end
          end

          describe '#states' do
            it 'returns a Set containing all (and only) the loaded state Class instances' do
              expect(@fsm.states).to eq(@states)
            end
          end
        end
      end
=end
    end
  end
end
