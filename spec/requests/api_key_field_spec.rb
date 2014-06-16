require 'spec_helper'
require 'support/shared_context'

describe 'api key form field' do

  before do
    @user = FactoryGirl.create(:user, :admin => true)
    @user2 = FactoryGirl.create(:user)
    login(@user)
  end

  context 'in show mode for same user' do
    before do
      get(user_path(@user))
    end

    it 'should be visible' do
      assert_select('div.user_api_key', true)
    end

    it 'should not have regenerate link' do
      assert_select('div.user_api_key a', :text => /Regenerate/, :count => 0)
    end
  end

  context 'in edit mode for same user' do
    before do
      get(edit_user_path(@user))
    end

    old_key = nil

    it 'should be visible' do
      # Store for later
      assert_select('div.user_api_key', true) do |e|
        old_key = e.to_s
      end
    end

    it 'should have regenerate link' do
      assert_select('div.user_api_key a', :text => /Regenerate/, :count => 1)
    end

    context 'on regenerate' do
      it 'should redirect back to user path' do
        response = put(regenerate_key_user_path(@user))
        expect(response).to redirect_to edit_user_path(@user)
      end

      it 'should have a new key' do
        assert_select('div.user_api_key') do |e|
          expect(old_key).not_to eq e.to_s
        end
      end
    end
  end

  context 'in show mode for different user' do
    before do
      get(user_path(@user2))
    end

    it 'should not be visible' do
      assert_select('div.user_api_key', false)
    end
  end

  context 'in edit mode for different user' do
    before do
      get(edit_user_path(@user2))
    end

    it 'should not be visible' do
      assert_select('div.user_api_key', false)
    end
  end
end
