require 'rails_helper'

describe "broadcasts" do
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
      3.times{ create(:broadcast, recipients: [@user1]) }
    end

    it 'index should work' do
      get_s(broadcasts_path)
    end
  end

  context 'for regular users' do
    before do
      @user2, @user3 = create(:user), create(:user)
    end

    it 'new_with_users should disable the locale select box' do
      post_s(new_with_users_broadcasts_path, params: {selected: {@user2.id => '1', @user3.id => '1'}})

      # Change language box should be disabled since this is a rendering POST request.
      assert_select('select#locale[disabled=disabled]', true)
    end

    it 'create and show should work', :sms do
      post(broadcasts_path,
        params: {
          broadcast: {
            recipient_selection: 'specific',
            recipient_ids: ["user_#{@user2.id}", "user_#{@user3.id}"],
            medium: 'sms',
            which_phone: 'both',
            subject: '',
            body: 'foo bar'
          }
        })

      expect(configatron.outgoing_sms_adapter.deliveries.size).to eq 1
      expect(response.status).to redirect_to(broadcast_path(assigns(:broadcast)))
      expect(flash[:success]).not_to be_nil
      follow_redirect!
      expect(response).to be_success
    end
  end

  context 'for users with no phone', :sms do
    before do
      @user2, @user3 = create(:user, phone: nil), create(:user, phone: nil)
    end

    it 'create should show error' do
      post_s(broadcasts_path,
        params: {
          broadcast: {
            recipient_selection: 'specific',
            recipient_ids: "#{@user2.id},#{@user3.id}",
            medium: 'sms_only',
            which_phone: 'both',
            subject: '',
            body: 'foo bar'
          }
        })

      expect(configatron.outgoing_sms_adapter.deliveries.size).to eq 0
      expect(flash[:success]).to be_nil
      expect(assigns(:broadcast).errors).not_to be_empty
    end
  end
end
