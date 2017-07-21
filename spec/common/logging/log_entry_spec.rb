require 'spec_helper'
require 'ladon'

module Ladon
  module Logging
    RSpec.describe LogEntry do
      describe '#new' do
        context 'when given an invalid message' do
          it 'raises an error' do
            not_arrays = [123, :sym, 'str', {}, Object.new]
            not_arrays.each { |thing| expect { LogEntry.new(thing, Level::NONE).to raise_error(StandardError) } }
          end
        end

        context 'when given an invalid level' do
          it 'raises an error' do
            [1, :one, 'one', [1], { one: 1 }].each do |thing|
              expect { LogEntry.new(['msg'], thing) }.to raise_error(StandardError)
            end
          end
        end

        context 'when given a valid message and level' do
          before do
            @message = ['msg']
            @level = Level::ERROR
            @time = Time.now
            allow(Time).to receive(:now).and_return(@time)
          end

          subject(:entry) { LogEntry.new(@message, @level) }

          it { is_expected.to have_attributes(level: @level, msg_lines: @message, time: @time) }
        end
      end

      describe 'to_ methods' do
        before do
          @message = %i[msg1 msg2]
          @level = Level::ERROR
          @time = Time.now
          allow(Time).to receive(:now).and_return(@time)
        end

        let(:entry) { LogEntry.new(@message, @level) }

        describe '#to_h' do
          subject { -> { entry.to_h } }

          let(:expected_hash) do
            {
              level: @level,
              time: @time,
              msg_lines: @message
            }
          end

          it { is_expected.not_to raise_error }

          it 'returns the existing flags arrtibute as a hash' do
            expect(subject.call).to eq(expected_hash)
          end
        end

        describe '#to_s' do
          subject { -> { entry.to_s } }

          let(:expected_string) do
            "#{@level} at #{@time.strftime('%T')}\n"\
            "\t#{@message[0]}\n\t#{@message[1]}"
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
