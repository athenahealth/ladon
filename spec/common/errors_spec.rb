require 'spec_helper'
require 'ladon'

module Ladon
  module Modeler
    describe InvalidStateTypeError do
      let(:state_type) { BasicObject }
      let(:error) { InvalidStateTypeError.new(state_type) }


      context 'when raised' do
        subject { -> { raise error } }

        it { is_expected.to raise_error(error, state_type) }
      end
    end
  end
end
