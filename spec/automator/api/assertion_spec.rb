require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    module API
      RSpec.describe Assertions do
        subject(:asserter) do
          Automation.new(Ladon::Automator::Config.new)
        end

        describe '#assert' do
          let(:msg) { 'msg' }
          context 'when given no block' do
            it 'raises an error' do
              expect{asserter.assert(msg)}.to raise_error(StandardError)
            end
          end

          context 'when given a block' do
            context 'when the block is safe (will not raise an error)' do
              it 'does not raise an error' do
                expect{asserter.assert(msg) { true }}.not_to raise_error
                expect{asserter.halting_assert(msg) { true }}.not_to raise_error
              end
            end

            context 'when the block is unsafe' do
              context 'when the assertion is halting' do
                it 'raises an AssertionFailedError' do
                  expect{asserter.halting_assert(msg) { raise }}.to raise_error(Assertions::AssertionFailedError)
                end
              end

              context 'when the assertion is not halting' do
                it 'does not raise' do
                  expect{asserter.assert(msg) { raise }}.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
