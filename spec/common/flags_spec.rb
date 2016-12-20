require 'spec_helper'
require 'ladon'

module Ladon
  RSpec.describe Flags do
    let(:flags) { Ladon::Flags.new(in_hash: in_hash) }

    describe '#new' do
      subject { -> { flags } }

      context 'when called without an in_hash or a non-hash value' do
        let(:in_hash) { nil }

        it { is_expected.not_to raise_error }
      end

      context 'when called with an in_hash' do
        let(:in_hash) { { a: 1, b: 2 } }

        it { is_expected.not_to raise_error }
      end
    end

    describe '#get' do
      let(:key) { :a }
      let(:value) { 1 }
      let(:default_value) { 2 }
      let(:in_hash) { { key => value } }
      subject { -> { flags.get(request_key, default_to: default_value) } }

      context 'when requesting the value for an existing flag key' do
        let(:request_key) { key }
        it { is_expected.not_to raise_error }

        it 'returns the existing value mapped to the given key' do
          expect(subject.call).to eq(value)
        end
      end

      context 'when requesting the value for a non-existing flag key' do
        let(:request_key) { :b }

        it 'returns the existing value mapped to the given key' do
          expect(subject.call).to eq(default_value)
        end
      end
    end

    describe 'to_ methods' do
      let(:in_hash) { { a: 1, b: 2 } }

      describe '#to_h' do
        subject { -> { flags.to_h } }

        it { is_expected.not_to raise_error }

        it 'returns the existing flags arrtibute as a hash' do
          expect(subject.call).to eq(in_hash)
        end
      end

      describe '#to_s' do
        let(:expected_string) { "a  => 1\nb  => 2" }
        subject { -> { flags.to_s } }

        it { is_expected.not_to raise_error }

        it 'returns the existing flags arrtibute as a string' do
          expect(subject.call).to eq(expected_string)
        end
      end
    end
  end
end
