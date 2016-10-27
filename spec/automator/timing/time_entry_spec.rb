require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    module Timing
      RSpec.describe TimeEntry do
        describe '#new' do

          context 'when given no name' do
            it 'raises an error' do
              expect{TimeEntry.new(nil)}.to raise_error(StandardError)
            end
          end

          context 'when given a name' do
            subject(:entry) { TimeEntry.new(entry_name)}
            let(:entry_name) { 'entry name' }

            it { is_expected.to have_attributes(name: entry_name)}
          end
        end

        describe '#start' do
          subject(:entry) { TimeEntry.new('entry_name')}

          before do
            @time = Time.now
            allow(Time).to receive(:now).and_return(@time)
            entry.start
          end

          it {is_expected.to have_attributes(start_time: @time)}
        end

        describe '#end' do
          subject(:entry) { TimeEntry.new('entry_name')}

          before do
            @time = Time.now
            allow(Time).to receive(:now).and_return(@time)
            entry.end
          end

          it {is_expected.to have_attributes(end_time: @time)}
        end
      end
    end
  end
end
