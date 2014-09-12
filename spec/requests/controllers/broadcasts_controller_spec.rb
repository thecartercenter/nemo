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

    # Change language link should be hidden since this is a rendering POST request.
    assert_select('#locale_form_link', false)
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

  context 'for users with no phone' do
    before do
      @user3 = create(:user, phone: nil)
      @user4 = create(:user, phone: nil)
    end

    it 'create should show error' do
      post_s(broadcasts_path, broadcast: {
        recipient_ids: [@user3.id, @user4.id],
        medium: 'sms_only',
        which_phone: 'both',
        subject: '',
        body: 'foo bar'
      })
      expect(flash[:success]).to be_nil
      expect(assigns(:broadcast).errors).not_to be_empty
    end
  end
end
