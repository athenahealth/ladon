require 'spec_helper'
require 'ladon'

module Ladon
  # Because why not?
  module Version
    describe '::STRING' do
      subject { Ladon::Version::STRING }

      it { is_expected.to be_a(String) }
    end
  end
end
