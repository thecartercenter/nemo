require 'spec_helper'

describe 'authorization' do

  before :all do
    @admin = create(:user, :admin => true)
    login(@admin)
  end

  describe @admin do
    it 'should be able to edit self in basic mode' do
      get(edit_user_path(@admin, :mode => nil, :mission_name => nil))
      assert_response :success
    end
  end
end
