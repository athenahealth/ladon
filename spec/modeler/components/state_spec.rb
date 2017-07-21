require 'spec_helper'
require 'ladon'

class ExampleState < Ladon::Modeler::State
  transition 'ExampleTransitionTarget1' do |t|
    t.meta('index', 1)
  end

  transition 'ExampleTransitionTarget2' do |t|
    t.meta('index', 2)
  end
end

class ExampleStateSubclass < ExampleState
  transition 'ExampleTransitionTarget3' do |t|
    t.meta('index', 3)
  end

  transition 'ExampleTransitionTarget4' do |t|
    t.meta('index', 4)
  end
end

module Ladon
  module Modeler
    RSpec.describe State do
      describe '.transitions' do
        context 'when .transitions is not overridden' do
          subject { State.transitions }

          it { is_expected.to be_an(Enumerable) }
          it { is_expected.to be_empty }
        end

        context 'when .transition is used' do
          subject { ExampleState.transitions }

          it { is_expected.to be_an(Enumerable) }
          it { is_expected.to(satisfy { |ts| ts.length == 2 }) }
          it { is_expected.to include(a_kind_of(Ladon::Modeler::Transition)) }
        end

        context 'when .transition is used in subclass and parent' do
          subject { ExampleStateSubclass.transitions }

          it { is_expected.to be_an(Enumerable) }
          it { is_expected.to(satisfy { |ts| ts.length == 4 }) }
          it { is_expected.to include(a_kind_of(Ladon::Modeler::Transition)) }
        end
      end
    end
  end
end
