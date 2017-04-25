require 'spec_helper'

describe Tag do
  it_behaves_like "has a uuid"

  it "should force name to lowercase" do
    tag = create(:tag, name: 'ABC')
    expect(tag.reload.name).to eq 'abc'
  end
end
