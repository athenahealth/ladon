require 'spec_helper'
require 'ladon'

module Ladon
  RSpec.describe Config do
    describe 'to_ methods' do
      let(:config) { Ladon::Config.new(id: config_id, log_level: config_level, flags: config_flags, test_class_name: config_class_name, test_file_path: config_file_path) }
      let(:config_id) { '123456' }
      let(:config_level) { nil }
      let(:config_flags) { { a: 1, b: 2 } }
      let(:config_class_name) {'Test Class Name'}
      let(:config_file_path) {'lib/automations/test_file_path.rb'}

      describe '#to_h' do
        subject { -> { config.to_h } }

        let(:expected_hash) { { id: config_id, test_class_name: config_class_name, test_file_path: config_file_path, log_level: 'ERROR', flags: config_flags } }

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
            "Test Class Name: #{config_class_name}",
            "Test File Path: #{config_file_path}",
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
