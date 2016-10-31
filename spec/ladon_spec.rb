require 'spec_helper'
require 'ladon'

module Ladon
  module Version
    describe '::STRING' do
      subject { Ladon::Version::STRING }

      # Because why not
      it { is_expected.to be_a(String)}
    end
  end
end