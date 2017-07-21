# frozen_string_literal: true

require 'spec_helper'
require 'ladon'

module Ladon
  RSpec.describe Flag do
    describe '#new' do
      subject { -> { Flag.new(:flag_name) } }

      it { is_expected.not_to raise_error }
    end

    describe '#feed' do
      context 'when the flag has no handler' do
        subject { -> { Flag.new(:flag_name_two).feed(Bundle.new) } }

        it { is_expected.to raise_error(BlockRequiredError) }
      end

      context 'when the flag has a handler' do
        let(:flag) { Flag.new(:flag_name_three) {} }
        subject { -> { flag.feed(Bundle.new) } }

        it { is_expected.not_to raise_error }
      end
    end

    describe '#get_value' do
      let(:flag) { Flag.new(:a_name, default: :hard_default, class_override: can_override) }
      let(:bundle) { Bundle.new }
      subject { flag.get_value(bundle) }

      context 'when class override is enabled' do
        let(:can_override) { true }

        context "when the bundle's class defines the conventional override method" do
          let(:bundle) do
            Class.new(Bundle) do
              def self.default_a_name
                :overridden_default
              end
            end.new
          end

          it { is_expected.to eq(:overridden_default) }
        end

        context "when the bundle's class does not define the conventional override method" do
          it { is_expected.to eq(:hard_default) }
        end
      end

      context 'when class override is disabled' do
        let(:can_override) { false }

        it { is_expected.to eq(:hard_default) }
      end
    end

    describe '#to_s' do
      subject { Flag.new(:flag_name).to_s }

      it { is_expected.to be_an_instance_of(String) }
    end

    describe '#to_h' do
      subject { Flag.new(:flag_name).to_h }

      it { is_expected.to be_an_instance_of(Hash) }
    end

    describe '#to_json' do
      subject { Flag.new(:flag_name).to_json }

      it { is_expected.to be_an_instance_of(String) }

      it 'is valid JSON' do
        expect { JSON.parse(subject.to_json) }.not_to raise_error
      end
    end
  end

  class ExampleOne; extend HasFlags; end

  class ExampleTwo
    extend HasFlags

    B_FLAG = make_flag(:b_flag)

    def flags
      {}
    end
  end

  class ExampleThree < ExampleTwo; D_FLAG = make_flag(:d_flag) {}; end

  RSpec.describe HasFlags do
    describe '.make_flag' do
      subject { ExampleOne.make_flag(:c_flag, default: :c, class_override: true) {} }

      it { is_expected.to be_an_instance_of(Flag) }

      it { is_expected.to be_frozen }

      it 'matches the args passed to the make_flag function' do
        expect(subject.name).to eq(:c_flag)
        expect(subject.default).to eq(:c)
        expect(subject.class_override).to eq(true)
        expect(subject.handler).to be_an_instance_of(Proc)
      end
    end

    describe '.get_flags' do
      subject { ExampleThree.all_flags }

      it { is_expected.to be_an_instance_of(Array) }

      it { is_expected.to contain_exactly(ExampleThree::D_FLAG, ExampleTwo::B_FLAG) }
    end

    describe '#get_flag_value' do
      subject { -> { ExampleTwo.new.get_flag_value(ExampleTwo::B_FLAG) } }

      it { is_expected.not_to raise_error }
    end

    describe '#handle_flag' do
      context 'when flag has a handler' do
        subject { -> { ExampleThree.new.handle_flag(ExampleThree::D_FLAG) } }

        it { is_expected.not_to raise_error }
      end

      context 'when flag does not have a handler' do
        subject { -> { ExampleTwo.new.handle_flag(ExampleTwo::B_FLAG) } }

        it { is_expected.to raise_error(BlockRequiredError) }
      end
    end
  end
end
