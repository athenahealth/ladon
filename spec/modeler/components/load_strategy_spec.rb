# frozen_string_literal: true

require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe LoadStrategy do
      describe '.nested_strategy_for' do
        subject { -> { LoadStrategy.nested_strategy_for(argument) } }

        context 'when the argument is a valid LoadStrategy' do
          let(:argument) { LoadStrategy::LAZY }

          it { is_expected.not_to raise_error }

          it 'returns a valid LoadStrategy' do
            expect(LoadStrategy::ALL).to(include { subject })
          end

          it 'returns the correct nested strategy' do
            expect(LoadStrategy::NESTING[argument]).to eq(subject.call)
          end
        end

        context 'when the argument is a valid LoadStrategy' do
          let(:argument) { nil }

          it { is_expected.to raise_error(ArgumentError) }
        end
      end
    end
  end
end
