require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe FiniteStateMachine do

      describe '#merge' do
        subject(:fsm) { FiniteStateMachine.new }

        context 'when the target is a different type than the subject' do
          let(:target) { Class.new(FiniteStateMachine).new }

          it 'will raise an invalid merge error' do
            expect {fsm.merge(target)}.to raise_error(InvalidMergeError)
          end
        end

        context 'when the target is the same type as the subject' do
          let(:target) { FiniteStateMachine.new }

          it 'will not raise an error' do
            expect {fsm.merge(target)}.not_to raise_error
          end

          context 'when the target has no states the subject does not' do
            let(:target) { FiniteStateMachine.new}

            it 'adds the states from the target to the subject'  do
              expect {fsm.merge(target)}.not_to change{fsm.states}
            end
          end

          context 'when the target has states the subject does not' do
            let(:different_state) { Class.new(Ladon::Modeler::States::State) }
            let(:target) { FiniteStateMachine.new(start_state: different_state)}

            it 'adds the states from the target to the subject'  do
              expect {fsm.merge(target)}.to change{fsm.states}.from(fsm.states).to(fsm.states | target.states)
            end
          end

          # TODO: transition merging test
          # TODO: context merging test
        end
      end

      describe 'when creating a finite state machine' do
        before do
          @fsm = nil
        end

        it 'does not require any arguments to instantiate' do
          expect {@fsm = FiniteStateMachine.new}.to change{@fsm}.from(nil).to(FiniteStateMachine)
        end

        describe 'when specifying a starting state' do
          before do
            @start_state = Class.new(States::State)
            @fsm = FiniteStateMachine.new(start_state: @start_state)
          end

          it 'creates a current_state tracker that is initialized to an instance of the starting state' do
            expect(@fsm.current_state).to be_an_instance_of(@start_state)
          end
        end

        describe 'when specifying contexts' do
          before do
            @contexts = {}
          end

          describe 'when there are no contexts' do

          end

          describe 'when there are contexts' do
            #@contexts['a'] = Object.new
          end

          it 'can take an empty hash of contexts' do
            expect{FiniteStateMachine.new(contexts: @contexts)}.not_to raise_error
          end

          it 'can take a hash containing a single context' do
            @contexts['a'] = Object.new
            expect{FiniteStateMachine.new(contexts: @contexts)}.not_to raise_error
          end
        end
      end

      describe 'when working with an existing finite state machine' do
        before do
          @fsm = FiniteStateMachine.new
        end

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
            expect {@fsm.load_state_type(Class.new(States::State))}.not_to raise_error
            [1, 2.2, :symbol, '', {}, []].each do |ex|
              expect{@fsm.load_state_type(ex)}.to raise_error(StandardError, "#{ex} is not a State")
            end
          end

          it 'will load multiple states' do
            newtype = Class.new(States::State)
            @fsm.load_state_type(newtype)
            expect(@fsm.state_count).to eq(1)
            expect(@fsm.states).to eq(Set.new([newtype]))

            newtype2 = Class.new(States::State)
            @fsm.load_state_type(newtype2)
            expect(@fsm.state_count).to eq(2)
            expect(@fsm.states).to eq(Set.new([newtype, newtype2]))
          end

          it 'does not change when loading an already known state' do
            newtype = Class.new(States::State)
            expect {@fsm.load_state_type(newtype)}.to change {@fsm.state_count}.from(0).to(1)
            expect {@fsm.load_state_type(newtype)}.not_to change {@fsm.state_count}.from(1)
          end
        end

        describe 'when the machine has at least one state' do
          before do
            newtype = Class.new(States::State)
            newtype2 = Class.new(States::State)
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
    end
  end
end
