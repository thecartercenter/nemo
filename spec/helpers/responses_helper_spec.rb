require 'rails_helper'

describe ResponsesHelper do
  let(:resp) { build(:response) }

  it "reviewed_status not 'pending' if response has not been checked out in the last 10 minutes" do
    expect(helper.reviewed_status(resp)).not_to eq('Pending')
  end

  it "reviewed_status is 'pending' if response has been checked out in the last 10 minutes" do
    resp.checked_out_at = 9.minutes.ago
    expect(helper.reviewed_status(resp)).to eq('Pending')
  end

  it "reviewed_status not 'pending' if response has been checked out over 10 minutes" do
    resp.checked_out_at = 11.minutes.ago
    expect(helper.reviewed_status(resp)).not_to eq('Pending')
  end
end
