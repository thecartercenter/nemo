require 'rails_helper'

describe "authentication" do
  it "should be logged out immediately if user is set to inactive" do
    user = create(:user)
    login(user)
    get '/en'
    expect(response).to be_success
    user.activate!(false)
    get '/en'
    expect(response).to redirect_to("/en/login")
  end
end
