require 'spec_helper'
require 'ladon'

module Ladon
  describe HasContexts do
    let(:has_context_class) { Class.new { include Ladon::HasContexts } }
    let(:instance) { has_context_class.new }

    describe '#contexts=' do
      subject { lambda { instance.contexts = inputs } }

      context 'when argument is not a Hash' do
        let(:inputs) { [1, 2, 3] }

        it { is_expected.to raise_error(StandardError) }
      end

      context 'when argument is a Hash' do
        context 'when the argument contains a non-symbol key' do
          let(:inputs) { {'a' => 1} }

          it { is_expected.to raise_error(StandardError) }
        end

        context 'when the argument contains only symbols as keys' do
          context 'when the argument contains a value that is not a Context' do
            let(:inputs) { {test: 1} }

            it { is_expected.to raise_error(StandardError) }
          end

          context 'when the argument contains only Contexts as values' do
            let(:inputs) { {test: Ladon::Context.new('test', 1)} }

            it { is_expected.not_to raise_error }
          end
        end
      end
    end
  end
end