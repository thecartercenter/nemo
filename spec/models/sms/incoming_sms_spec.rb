require 'rails_helper'

describe Sms::Incoming, :sms do
  before do
    @user1 = FactoryGirl.create(:user, phone: '1234567890')
  end

  it 'should lookup user' do
    sms = Sms::Incoming.create!(from: '1234567890', body: 'test')
    expect(sms.user).to eq @user1
  end

  it 'should set user to nil if unrecognized number' do
    sms = Sms::Incoming.create!(from: '6667778888', body: 'test')
    expect(sms.user).to be_nil
  end
end
