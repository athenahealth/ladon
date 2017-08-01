require 'spec_helper'
require 'ladon'

module Ladon
  module Timing
    RSpec.describe Timer do
      let(:timer_name) { 'some_name' }
      subject(:timer) { Timer.new }

      describe '#new' do
        it { is_expected.to have_attributes(entries: []) }
      end

      describe '#for' do
        context 'when given no block' do
          it 'raises an error' do
            expect { subject.for(timer_name) }.to raise_error(StandardError)
          end
        end

        context 'when given a block' do
          it 'records a new entry with a start time' do
            expect { subject.for(timer_name) {} }.to change { subject.entries.size }.by(1)
            expect(subject.entries.last.start_time).to be_a(Time)
          end

          context 'when the block is safe (one that will not raise)' do
            # We will use an empty block, which would appear to be inherently safe.
            it 'does not raise an error' do
              expect { subject.for(timer_name) {} }.not_to raise_error
            end

            it 'records a new entry with an end time' do
              subject.for(timer_name) {}
              new_entry = subject.entries.last
              expect(new_entry.end_time).to be_a(Time) # end time should be a time
              expect(new_entry.end_time).to be >= new_entry.start_time # end time should be after start time
            end
          end

          context 'when given an unsafe block' do
            let(:error_type) { Class.new(StandardError) }
            it 'will raise the error from the block' do
              expect { subject.for(timer_name) { raise error_type } }.to raise_error(error_type)
            end
          end
        end
      end

      describe '#total_time' do
        context 'when no entries exist' do
          it 'returns a total duration of 0' do
            expect(subject.total_time).to eq(0)
          end
        end
        context 'when one entry exists' do
          it 'returns a total duration equal to single entry' do
            # sleep in seconds
            subject.for(timer_name) { sleep 0.5 }
            # duration should be identical, but in minutes
            expect(subject.total_time.round(3)).to eq((0.5 / 60).round(3))
          end
        end

        context 'when multiple entries exists' do
          it 'returns a total duration equal to the sum of entries' do
            # sleep in seconds
            subject.for(timer_name) { sleep 0.25 }
            subject.for(timer_name) { sleep 0.5 }
            # duration should be identical to sum, but in minutes
            expect(subject.total_time.round(3)).to eq(((0.25 + 0.5) / 60).round(3))
          end
        end
      end

      describe 'to_ methods' do
        before(:each) do
          @timer = Timer.new
          @timer.for(timer_name) {}
          @new_entry = @timer.entries.last
        end

        describe '#to_h' do
          subject { -> { @timer.to_h } }
          let(:expected_hash) { { @new_entry.name => @new_entry.to_h } }

          it { is_expected.not_to raise_error }

          it 'returns the existing entries arrtibute as a hash' do
            expect(subject.call).to eq(expected_hash)
          end
        end

        describe '#to_s' do
          subject { -> { @timer.to_s } }
          let(:expected_string) { @new_entry.to_s }

          it { is_expected.not_to raise_error }

          it 'returns the existing entries arrtibute as a string' do
            expect(subject.call).to eq(expected_string)
          end
        end
      end
    end
  end
end
