require 'spec_helper'

describe 'unauthenticated submissions', :type => :request do

  context 'to mission where they are not allowed' do
    before do
      # Allow flag defaults to zero
      @mission = FactoryGirl.create(:mission)
    end

    it 'should be rejected' do
      post("/m/#{@mission.compact_name}/noauth/submission/")
      assert_response(:unauthorized)
      expect(response.body).to eq('UNAUTHENTICATED_SUBMISSIONS_NOT_ALLOWED')
    end
  end

end