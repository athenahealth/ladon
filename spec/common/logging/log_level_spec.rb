# frozen_string_literal: true

require 'spec_helper'
require 'ladon'

module Ladon
  module Logging
    RSpec.describe Level do
      let(:invalid_levels) { [1, :one, 'one', [1], { one: 1 }] }

      describe '#valid?' do
        context 'when given an invalid level' do
          it 'returns false' do
            invalid_levels.each { |inv| expect(Level.valid?(inv)).to be false }
          end
        end

        context 'when given a valid logging level' do
          it 'returns true' do
            Level::ALL.each { |level| expect(Level.valid?(level)).to be true }
          end
        end
      end

      describe '#enabled_for' do
        context 'when given an invalid logging level' do
          it 'returns an empty array' do
            invalid_levels.each { |inv| expect(Level.enabled_for(inv)).to match_array([]) }
          end
        end

        context 'when given a valid logging level' do
          it 'returns an array containing the level and all levels to the "right" in the enumeration' do
            Level::ALL.each_with_index do |level, idx|
              enabled_levels = Level.enabled_for(level)
              to_the_left = Level::ALL[0..idx] - [level]

              expect(enabled_levels).to eq(Level::ALL - to_the_left)
            end
          end
        end
      end
    end
  end
end
