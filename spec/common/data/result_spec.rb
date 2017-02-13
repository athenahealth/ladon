require 'spec_helper'
require 'ladon'

module Ladon
  RSpec.describe Result do
    let(:key) { 'key' }
    let(:result) { Ladon::Result.new(config: Ladon::Config.new) }

    describe '#record_data' do
      let(:value) { 'value' }
      subject { -> { result.record_data(key, value) } }

      context 'when no key is given' do
        let(:key) { nil }
        it { is_expected.to raise_error(StandardError) }
      end

      context 'when a new key is given' do
      end

      context 'when an existing key is given' do
        let(:existing_val) { "#{value}2" }
        before { result.record_data(key, existing_val) }

        it { is_expected.to change { result.data_log[key] }.from(existing_val).to(value) }
      end

      context 'when data key already exists' do
        before { result.record_data(key, value) }

        it 'overwrites the previous value' do
          newval = "#{value}2"
          expect { result.record_data(key, newval) }.to change { result.data_log[key] }.from(value).to(newval)
        end
      end

      context 'when data key does not already exist' do
        it 'creates a new data log key with the given value' do
          expect { result.record_data(key, value) }.to change { result.data_log[key] }.from(nil).to(value)
        end
      end
    end

    describe '#failure' do
      subject { Ladon::Result.new(config: Ladon::Config.new) }

      context 'when the result is currently marked a success' do
        it 'marks the result as failed' do
          expect { subject.failure }.to change(subject, :status).from(Result::SUCCESS_FLAG).to(Result::FAILURE_FLAG)
        end
      end

      context 'when the result is already marked an error' do
        before { subject.error }

        it 'does not change the status' do
          expect { subject.failure }.not_to change(subject, :status).from(Result::ERROR_FLAG)
        end
      end
    end

    describe '#failure?' do
      let(:result) { Ladon::Result.new(config: Ladon::Config.new) }
      subject { result.failure? }

      context 'when the result is marked as a failure' do
        before { result.failure }

        it { is_expected.to be true }
      end

      context 'when the result is marked as a error' do
        before { result.error }

        it { is_expected.to be false }
      end

      context 'when the result is marked as a success' do
        it { is_expected.to be false }
      end
    end

    describe 'to_ methods' do
      let(:result) { Ladon::Result.new(config: Ladon::Config.new(id: '123456'),
                                       logger: Ladon::Logging::Logger.new(level: Logging::Level::ERROR),
                                       timer: Ladon::Timing::Timer.new) }

      describe '#to_h' do
        subject { -> { result.to_h } }

        let(:expected_hash) do
          {
            status: :SUCCESS,
            config: { id: '123456', log_level: 'ERROR', flags: {} },
            timings: {},
            log: { level: :ERROR, entries: [] },
            data_log: {}
          }
        end

        it { is_expected.not_to raise_error }

        it 'returns the results representation as a hash' do
          expect(subject.call).to eq(expected_hash)
        end
      end

      describe '#to_s' do
        subject { -> { result.to_s } }

        before { result.record_data(:key, :value) }

        let(:expected_string) do
          [
            "STATUS: SUCCESS\n",
            'CONFIGURATIONS:',
            "Id: 123456\nLog Level: ERROR\nFlags:\n\n",
            "TIMINGS:\n\n",
            'LOG MESSAGES:',
            "Level: ERROR\nEntries:\n\n",
            'DATA LOG:',
            'key  => value'
          ].join("\n")
        end

        it { is_expected.not_to raise_error }

        it 'returns the existing flags attribute as a string' do
          expect(subject.call).to eq(expected_string)
        end
      end

      describe '#to_json' do
        subject { -> { result.to_json } }

        it { is_expected.not_to raise_error }

        it 'produces valid JSON' do
          expect{JSON.parse(subject.call)}.not_to raise_error
        end
      end
    end
  end
end
