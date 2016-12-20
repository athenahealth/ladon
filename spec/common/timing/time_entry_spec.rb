require 'spec_helper'
require 'ladon'

module Ladon
  module Timing
    RSpec.describe TimeEntry do
      describe '#new' do
        context 'when given no name' do
          it 'raises an error' do
            expect { TimeEntry.new(nil) }.to raise_error(StandardError)
          end
        end

        context 'when given a name' do
          subject(:entry) { TimeEntry.new(entry_name) }
          let(:entry_name) { 'entry name' }

          it { is_expected.to have_attributes(name: entry_name) }
        end
      end

      describe '#start' do
        subject(:entry) { TimeEntry.new('entry_name') }

        before do
          @time = Time.now
          allow(Time).to receive(:now).and_return(@time)
          entry.start
        end

        it { is_expected.to have_attributes(start_time: @time) }
      end

      describe '#end' do
        subject(:entry) { TimeEntry.new('entry_name') }

        before do
          @time = Time.now
          allow(Time).to receive(:now).and_return(@time)
          entry.end
        end

        it { is_expected.to have_attributes(end_time: @time) }
      end

      describe '#duration' do
        before do
          @time = Time.now
          allow(Time).to receive(:now).and_return(@time)
          @entry = TimeEntry.new('entry_name')
        end
        subject { -> { @entry.duration } }

        context 'when a time attribute is not available' do
          it { is_expected.not_to raise_error }

          it 'returns -1.0' do
            expect(subject.call).to eq(-1.0)
          end
        end

        context 'when both times are present' do
          before do
            @entry = TimeEntry.new('entry_name')
            @entry.start
            @entry.end
          end
          it { is_expected.not_to raise_error }

          it 'returns the time difference' do
            expect(subject.call).to eq(0.0)
          end
        end
      end

      describe 'to_ methods' do
        before do
          @time = Time.now
          allow(Time).to receive(:now).and_return(@time)
          @entry = TimeEntry.new('entry_name')
          @entry.start
          @entry.end
        end

        describe '#to_h' do
          subject { -> { @entry.to_h } }

          let(:expected_hash) do
            {
              name: 'entry_name',
              start: @time,
              end: @time,
              duration: 0.0
            }
          end

          it { is_expected.not_to raise_error }

          it 'returns the existing flags arrtibute as a hash' do
            expect(subject.call).to eq(expected_hash)
          end
        end

        describe '#to_s' do
          subject { -> { @entry.to_s } }

          let(:expected_string) do
            [
              'entry_name',
              ' - Time Elapsed:  0.0',
              " - Started:  #{@time.strftime('%T')}",
              " - Ended:  #{@time.strftime('%T')}"
            ].join("\n")
          end

          it { is_expected.not_to raise_error }

          it 'returns the existing flags arrtibute as a string' do
            expect(subject.call).to eq(expected_string)
          end
        end
      end
    end
  end
end
