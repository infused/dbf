# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DBF::VERSION' do
  it 'is a string in the form n.n.n' do
    expect(DBF::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
