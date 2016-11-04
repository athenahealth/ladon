require 'spec_helper'
require 'ladon'

module Ladon
  module Automator
    RSpec.describe Config do
      subject(:config) { Ladon::Automator::Config.new }
    end
  end
end
