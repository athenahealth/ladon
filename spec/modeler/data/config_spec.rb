require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe Config do
      describe '#flags' do
        subject { Config.new.flags }

        it { is_expected.to be_an_instance_of(Ladon::Flags) }
      end
    end
  end
end
