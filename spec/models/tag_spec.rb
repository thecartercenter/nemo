require 'rails_helper'

describe Tag do
  it "should force name to lowercase" do
    tag = create(:tag, name: 'ABC')
    expect(tag.reload.name).to eq 'abc'
  end
end
