require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe State do
      describe '.transitions' do
        subject { lambda { State.transitions } }

        it { is_expected.to raise_error(MissingImplementationError, 'transitions') }
      end
    end
  end
end
