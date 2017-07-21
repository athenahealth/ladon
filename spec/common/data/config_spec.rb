# frozen_string_literal: true

require 'spec_helper'
require 'ladon'

module Ladon
  RSpec.describe Config do
    describe 'to_ methods' do
      let(:config) do
        Ladon::Config.new(
          id: config_id,
          log_level: config_level,
          flags: config_flags,
          class_name: class_name,
          path: path
        )
      end
      let(:config_id) { '123456' }
      let(:config_level) { nil }
      let(:config_flags) { { a: 1, b: 2 } }
      let(:class_name) { 'FooBar' }
      let(:path) { './lib/automations/foo/bar.rb' }

      describe '#to_h' do
        subject { -> { config.to_h } }

        let(:expected_hash) do
          {
            id: config_id,
            test_class_name: class_name,
            test_file_path: path,
            log_level: 'ERROR',
            flags: config_flags
          }
        end

        it { is_expected.not_to raise_error }

        it 'returns the existing flags attribute as a hash' do
          expect(subject.call).to eq(expected_hash)
        end
      end

      describe '#to_s' do
        subject { -> { config.to_s } }

        let(:expected_string) do
          [
            "Id: #{config_id}",
            "Test Class Name: #{class_name}",
            "Test File Path: #{path}",
            'Log Level: ERROR',
            'Flags:',
            "a  => 1\nb  => 2"
          ].join("\n")
        end

        it { is_expected.not_to raise_error }

        it 'returns the existing flags attribute as a string' do
          expect(subject.call).to eq(expected_string)
        end
      end
    end

    describe '#flags' do
      subject { Config.new.flags }

      it { is_expected.to be_an_instance_of(Hash) }
    end
  end
end
