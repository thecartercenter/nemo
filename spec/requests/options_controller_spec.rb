require 'spec_helper'

describe OptionsController do
  before do
    @user = create(:user)
    login(@user)
    allow(Option).to receive(:suggestions).and_return([Option.new(:name => 'foo')])
    get_s suggest_options_path, :q => 'foo'
  end

  it 'should return matching suggestions' do
    # The response is not super correct (e.g. id = null) but all we want to
    # test is that the controller calls suggestions and converts to json
    expect(response.body).to eq '[{"id":null,"name_translations":{"en":"foo"},"name":"foo","set_names":"","in_use?":false}]'
  end
end