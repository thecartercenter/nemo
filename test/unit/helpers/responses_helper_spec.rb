require 'spec_helper'

describe ResponsesHelper do

  it "reviewed_status not 'pending' if response has not been checked out in the last 10 minutes" do
    resp = build(:response)
    self.stubs(:tbool).returns('abba')

    expect(reviewed_status(resp)).to eq('abba')
    expect(reviewed_status(resp)).not_to eq(I18n.t("common.pending"))
  end

  it "reviewed_status is 'pending' if response has been checked out in the last 10 minutes" do
    resp = build(:response)
    resp.checked_out_at = 9.minutes.ago
    self.stubs(:tbool).returns('abba')

    expect(reviewed_status(resp)).not_to eq('abba')
    expect(reviewed_status(resp)).to eq(I18n.t("common.pending"))
  end

  it "reviewed_status not 'pending' if response has been checked out over 10 minutes" do
    resp = build(:response)
    resp.checked_out_at = 11.minutes.ago
    self.stubs(:tbool).returns('abba')

    expect(reviewed_status(resp)).to eq('abba')
    expect(reviewed_status(resp)).not_to eq(I18n.t("common.pending"))
  end
end
