require 'spec_helper'

describe "option suggestion" do
  let(:user) { create(:user) }
  let(:option) { create(:option, name: "Foo") }

  before do
    login(user)
    allow(Option).to receive(:suggestions).and_return([option])
  end

  it "should return matching suggestions" do
    get_s suggest_options_path, q: "foo"
    expect(response.body).to eq %Q|[{"id":"#{option.id}","latitude":null,"longitude":null,| <<
      %Q|"name_translations":{"en":"Foo"},"name":"Foo","set_names":"","in_use?":false}]|
  end
end
