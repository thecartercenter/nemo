require 'rails_helper'

describe 'basic authentication for xml requests' do

  before(:all) do
    @user = create(:user)
  end

  context 'when not already logged in' do
    it 'should be required' do
      get "/m/#{get_mission.compact_name}/formList"
      assert_response :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Basic realm="Application"'
    end
  end

  context 'when already logged in via web' do
    before do
      login(@user)
    end

    it 'should not be required' do
      get "/m/#{get_mission.compact_name}/formList"
      assert_response :success
    end
  end

end