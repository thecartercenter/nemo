require 'spec_helper'

describe Option do

  it 'should create cleanly' do
    create(:option, :name => 'Foo')
  end
end
