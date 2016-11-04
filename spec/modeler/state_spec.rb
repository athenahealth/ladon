require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    RSpec.describe State do
      describe '.transitions' do
        subject { -> { State.transitions } }

        it { is_expected.to raise_error(MissingImplementationError, 'self.transitions') }
      end
    end
  end
end
