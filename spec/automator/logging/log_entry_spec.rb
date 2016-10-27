require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    module Logging
      RSpec.describe LogEntry do
        describe '#new' do
          context 'when given an invalid message' do
            it 'raises an error' do
              not_arrays = [123, :sym, 'str', {}, Object.new]
              not_arrays.each {|thing| expect{LogEntry.new(thing, Level::NONE).to raise_error(StandardError)}}
            end
          end

          context 'when given an invalid level' do
            it 'raises an error' do
              [1, :one, 'one', [1], {one: 1}].each do |thing|
                expect{LogEntry.new(['msg'], thing)}.to raise_error(StandardError)
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
      end
    end
  end
end
