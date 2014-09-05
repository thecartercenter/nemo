require 'spec_helper'

describe BroadcastsController do
  before(:all) do
    @user1 = create(:user)
    @user2 = create(:user)
    login(@user1)
  end

  it 'index should work' do
    get_s(broadcasts_path)
  end

  it 'new_with_users should work' do
    post_s(new_with_users_broadcasts_path, selected: {@user1.id => '1', @user2.id => '1'})
  end

  it 'create and show should work' do
    post(broadcasts_path, broadcast: {
      recipient_ids: [@user1.id, @user2.id],
      medium: 'sms',
      which_phone: 'both',
      subject: '',
      body: 'foo bar'
    })
    expect(response.status).to redirect_to(broadcast_path(assigns(:broadcast)))
    expect(flash[:success]).not_to be_nil
    follow_redirect!
    expect(response).to be_success
  end
end
