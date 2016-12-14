require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    module Logging
      RSpec.describe Logger do
        describe '#new' do
          let(:logger) { Logger.new(level: level) }

          context 'when given an invalid logging level' do
            let(:level) { :invalid_level }
            it 'raises an error' do
              expect { logger }.to raise_error(StandardError)
            end
          end

          context 'when given a valid logging level' do
            let(:level) { Level::ERROR }
            let(:enabled_levels) { Level.enabled_for(level) }
            subject(:the_logger) { logger }

            it { is_expected.to have_attributes(level: level, entries: [], enabled_levels: enabled_levels) }
          end
        end

        describe '#log' do
          subject(:logger) { Logger.new(level: Level::ERROR) }

          context 'when called with a disabled level' do
            it 'does not retain a new entry' do
              expect { logger.log('message') }.not_to change { logger.entries.size }.from(0)
            end
          end

          context 'when called with an enabled level' do
            let(:message) { 'message' }
            let(:level) { Level::FATAL }

            it 'creates and retains a new LogEntry' do
              expect { logger.log(message, level: level) }.to change { logger.entries.size }.from(0).to(1)
              new_entry = logger.entries[0]
              expect(new_entry).to be_a(LogEntry)
              expect(new_entry).to have_attributes(msg_lines: [message], level: level)
            end
          end
        end

        describe 'to_ methods' do
          let(:logger) { Logger.new }
          describe '#to_h' do
            subject { -> { logger.to_h } }
            let(:expected_hash) { { level: Level::ERROR, entries: [] } }

            it { is_expected.not_to raise_error }

            it 'returns the existing flags arrtibute as a hash' do
              expect(subject.call).to eq(expected_hash)
            end
          end

          describe '#to_s' do
            let(:expected_string) { "Level: ERROR\nEntries:\n" }
            subject { -> { logger.to_s } }

            it { is_expected.not_to raise_error }

            it 'returns the existing flags arrtibute as a string' do
              expect(subject.call).to eq(expected_string)
            end
          end
        end

        describe 'convenience methods' do
          let(:test_msg) { 'message' }
          let(:compare_to) { Logger.new(level: Level::DEBUG).log(test_msg, level: level).msg_lines }
          subject(:convenience_target) { Logger.new(level: Level::DEBUG).send(meth_name, test_msg).msg_lines }

          describe '#debug' do
            let(:meth_name) { 'debug' }
            let(:level) { Level::DEBUG }

            it { is_expected.to eq(compare_to) }
          end

          describe '#info' do
            let(:meth_name) { 'info' }
            let(:level) { Level::INFO }

            it { is_expected.to eq(compare_to) }
          end

          describe '#warn' do
            let(:meth_name) { 'warn' }
            let(:level) { Level::WARN }

            it { is_expected.to eq(compare_to) }
          end

          describe '#error' do
            let(:meth_name) { 'error' }
            let(:level) { Level::ERROR }

            it { is_expected.to eq(compare_to) }
          end

          describe '#fatal' do
            let(:meth_name) { 'fatal' }
            let(:level) { Level::FATAL }

            it { is_expected.to eq(compare_to) }
          end
        end
      end
    end
  end
end
