require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    module Transitions
      RSpec.describe Transition do

        describe '#new' do
          context 'when not given a block' do
            subject(:transition) { Transition.new }

            it 'does not raise' do
              expect{transition}.not_to raise_error
            end

            it { is_expected.to have_attributes(target_loaded?: false, metadata: {}) }
          end

          context 'when given a block' do
            let(:transition) { Transition.new { |transition| block_behavior.call(transition) } }
            subject(:behavior) { lambda { transition } }

            context 'when the block takes more than one argument' do
              let(:block_behavior) { lambda {|transition, stuff| } }
              #subject { maker }

              it { is_expected.to raise_error(ArgumentError, 'wrong number of arguments (1 for 2)') }
            end

            context 'when the block takes no arguments' do
              let(:block_behavior) { lambda {} }
              #subject { maker }

              it { is_expected.to raise_error(ArgumentError, 'wrong number of arguments (1 for 0)') }
            end

            context 'when the block takes one argument' do
              let(:block_behavior) { lambda { |transition| } }
              #subject { maker }

              it { is_expected.not_to raise_error }

              context 'in the block itself' do
                let(:block_behavior) { lambda { |transition| transition.instance_variable_set('@block_arg', transition) } }
                subject { transition }

                it { is_expected.to satisfy { |trans| trans.instance_variable_get('@block_arg') == trans } }
              end
            end
          end
        end

        describe '#metadata' do
          let(:key) { :key }
          let(:value) { :value }

          subject { Transition.new {|t| t.meta(key, value)}.metadata }

          it { is_expected.to be_a_kind_of(Hash) }
          it { is_expected.to include(Hash[key, value]) }
        end

        describe '#meta' do
          let(:meta_key) { :key }
          let(:meta_value) { 'value' }
          let(:transition) { Transition.new }
          let(:executor) { lambda { transition.meta(meta_key, meta_value) } }

          subject(:execution) { executor.call }

          it { is_expected.to eq(meta_value) }

          it { expect{execution}.to change(transition, :metadata).from({}).to(Hash[meta_key, meta_value]) }
        end

        describe '#meta_for' do
          let(:meta_key) { :key }
          let(:meta_value) { 'value' }

          subject(:result) do
            Transition.new { |t| t.meta(meta_key, meta_value) }.meta_for(search_key)
          end

          context 'when search key exists' do
            let(:search_key) { meta_key }

            it { is_expected.to eq(meta_value) }
          end

          context 'when search key does not exist' do
            let(:search_key) { :some_other_key }

            it { is_expected.to eq(nil) }
          end

        end

        describe '#when' do
          context 'when specifying a block' do
            subject(:transition) { lambda { Transition.new.when {} } }

            it { is_expected.not_to raise_error }
          end

          context 'when no block is specified' do
            subject(:transition) { lambda { Transition.new.when } }

            it { is_expected.to raise_error(StandardError) }
          end
        end

        describe '#by' do
          context 'when specifying a block' do
            subject(:transition) { lambda { Transition.new.by {} } }

            it { is_expected.not_to raise_error }
          end

          context 'when no block is specified' do
            subject(:transition) { lambda { Transition.new.by } }

            it { is_expected.to raise_error(StandardError) }
          end
        end

        describe '#to_load_target_state_type' do
          let(:transition) { Transition.new }
          let(:behavior) { transition.to_load_target_state_type }
          subject { lambda { behavior } }

          context 'when no block is given' do
            it { is_expected.to raise_error(StandardError) }
          end

          context 'when block is given' do
            let(:behavior) { transition.to_load_target_state_type {} }

            before { allow(transition).to receive(:target_loaded?).and_return(loaded_status)}

            context 'when the target state type has already been loaded' do
              let(:loaded_status) { true }

              it { is_expected.to raise_error(StandardError) }
            end

            context 'when the target state type has not yet been loaded' do
              let(:loaded_status) { false }

              it { is_expected.not_to raise_error }
            end
          end
        end

        describe '#load_target_state_type' do
          let(:transition) { Transition.new {|t| block_behavior.call(t) } }
          let(:block_behavior) { lambda { |t| } }
          let(:behavior) { transition.load_target_state_type }
          subject { lambda { behavior }}

          context 'when target is loaded' do
            let(:block_behavior) { lambda { |t| t.to_load_target_state_type {} } }

            before { transition.load_target_state_type }

            it { is_expected.not_to change(transition, :target_loaded?).from(true) }

            it 'returns true' do
              expect(behavior).to be true
            end

            context 'when the transition has a target loader block' do

              subject { transition.instance_variable_get('@loader') }

              it { is_expected.not_to receive(:call) }
            end
          end

          context 'when target is not yet loaded' do
            context 'when a target loader has not been specified' do
              it { is_expected.to raise_error(NoMethodError) }
            end

            context 'when a target loader has been specified' do
              let(:block_behavior) { lambda { |t| t.to_load_target_state_type { } } }

              it { is_expected.to change{transition.target_loaded?}.from(false).to(true) }

              it 'calls the target loader' do
                loader = transition.instance_variable_get('@loader')
                expect(loader).to receive(:call)
                subject.call
              end
            end
          end
        end

        describe '#to_identify_target_state_type' do
          let(:transition) { Transition.new }
          let(:behavior) { transition.to_identify_target_state_type }
          subject { lambda { behavior } }

          context 'when no block is given' do
            it { is_expected.to raise_error(StandardError) }
          end

          context 'when block is given' do
            let(:behavior) { transition.to_identify_target_state_type {} }

            before { allow(transition).to receive(:target_loaded?).and_return(loaded_status)}

            context 'when the target state type has already been loaded' do
              let(:loaded_status) { true }

              it { is_expected.to raise_error(StandardError) }
            end

            context 'when the target state type has not yet been loaded' do
              let(:loaded_status) { false }

              it { is_expected.not_to raise_error }
            end
          end
        end

        describe '#identify_target_state_type' do
          let(:transition) { Transition.new { |t| block_behavior.call(t) } }
          let(:block_behavior) { lambda { |t| } }
          let(:behavior) { transition.identify_target_state_type }

          subject { lambda { behavior } }

          context 'when a target identifier is specified' do
            let(:target_type) { Class.new(Modeler::States::State) }
            let(:block_behavior) { lambda { |t| t.to_identify_target_state_type { target_type } } }

            context 'when the target has not been loaded' do
              it { is_expected.to raise_error(StandardError) }
            end

            context 'when the target has been loaded' do
              before { allow(transition).to receive(:target_loaded?).and_return(true) }

              subject { behavior }

              it { is_expected.to eq(target_type) }
            end
          end

          context 'when a target identifier is not specified' do
            context 'when the target has not been loaded' do
              it { is_expected.to raise_error(StandardError) }
            end

            context 'when the target has been loaded' do
              before { allow(transition).to receive(:target_loaded?).and_return(true) }
              it { is_expected.to raise_error(NoMethodError) }
            end
          end
        end

        describe '#valid_for?' do
          let(:transition) { Transition.new { |t| block_behavior.call(t) } }
          subject(:execution) { transition.valid_for?(nil) }

          context 'when the transition has no "when" blocks' do
            let(:block_behavior) { lambda { |_| } }

            it { is_expected.to be true }
          end

          context 'when the transition has one or more "when" blocks' do
            context 'when at least one "when" block returns true' do
              let(:block_behavior) { lambda { |t| t.when { |current_state| true } } }

              it { is_expected.to be true }
            end

            context 'when no "when" block returns true' do
              let(:block_behavior) { lambda { |t| t.when { |current_state| false } } }

              it { is_expected.to be false }
            end
          end
        end

        describe '#execute' do
          context '' do

          end
          #let(:transition) { Transition.new { |t| block_behavior.call(t) } }
          #subject(:execution) { transition.valid_for?(nil) }
        end
      end
    end
  end
end
