require 'spec_helper'

# Using request spec b/c Authlogic won't work with controller spec
describe BroadcastsController, type: :request do
  before(:all) do
    @user1 = create(:user)
    login(@user1)
  end

  context 'with no previous broadcasts' do
    it 'index should work' do
      get_s(broadcasts_path)
    end
  end

  context 'with previous broadcasts' do
    before do
      3.times{ create(:broadcast) }
    end

    it 'index should work' do
      get_s(broadcasts_path)
    end
  end

  context 'for regular users' do
    before do
      @user2, @user3 = create(:user), create(:user)
    end

    it 'new_with_users should work' do
      post_s(new_with_users_broadcasts_path, selected: {@user2.id => '1', @user3.id => '1'})

      # Change language box should be disabled since this is a rendering POST request.
      assert_select('select#locale[disabled=disabled]', true)
    end

    it 'create and show should work' do
      post(broadcasts_path, broadcast: {
        recipient_ids: [@user2.id, @user3.id],
        medium: 'sms',
        which_phone: 'both',
        subject: '',
        body: 'foo bar'
      })
      expect(configatron.outgoing_sms_adapter.deliveries.size).to eq 1
      expect(response.status).to redirect_to(broadcast_path(assigns(:broadcast)))
      expect(flash[:success]).not_to be_nil
      follow_redirect!
      expect(response).to be_success
    end
  end

  context 'for users with no phone' do
    before do
      @user2, @user3 = create(:user, phone: nil), create(:user, phone: nil)
    end

    it 'create should show error' do
      post_s(broadcasts_path, broadcast: {
        recipient_ids: [@user2.id, @user3.id],
        medium: 'sms_only',
        which_phone: 'both',
        subject: '',
        body: 'foo bar'
      })
      expect(configatron.outgoing_sms_adapter.deliveries.size).to eq 0
      expect(flash[:success]).to be_nil
      expect(assigns(:broadcast).errors).not_to be_empty
    end
  end

  context 'for users with no phone or email' do
    before do
      @user2, @user3 = create(:user, phone: nil, email: nil), create(:user, phone: nil, email: nil)
    end

    it 'new_with_users should redirect with error' do
      post(new_with_users_broadcasts_path, selected: {@user2.id => '1', @user3.id => '1'})
      expect(response).to redirect_to(users_path)
      expect(flash[:error]).to match(/None of the users you selected/)
    end
  end
end
