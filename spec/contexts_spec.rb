require 'spec_helper'
require 'ladon'

module Ladon
  describe HasContexts do
    let(:legit_context) { Ladon::Context.new('test', 1) }
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
            let(:inputs) { {test: legit_context } }

            it { is_expected.not_to raise_error }
          end
        end
      end
    end

    describe '#context' do
      subject { instance.context(name) }
      before { instance.contexts = {test: legit_context} }

      context 'when a context exists for the specified name' do
        let(:name) { 'test' }

        it { is_expected.to eq(legit_context) }
      end

      context 'when a context does not exist for the specified name' do
        let(:name) { 'whatever' }

        it { is_expected.to be_nil }
      end
    end

    describe '#merge_contexts' do
      let(:existing_context) { Context.new('a', :a) }
      let(:current_contexts) { { a: existing_context } }
      subject { lambda { instance.merge_contexts(target) } }

      before { instance.contexts = current_contexts }

      context 'when the target has a colliding context' do
        let(:target) { { a: existing_context } }

        it { is_expected.not_to change(instance, :contexts).from(current_contexts) }
      end

      context 'when the target has no colliding contexts' do
        let(:target) { { test: legit_context } }

        it { is_expected.to change{instance.context('test')}.from(nil).to(legit_context) }
      end
    end
  end
end