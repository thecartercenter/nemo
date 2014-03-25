require 'test_helper'

class ResponsesHelperTest < ActionView::TestCase

  test "reviewed_status not 'pending' if response has not been checked out in the last 10 minutes" do
    resp = FactoryGirl.build(:response)
    self.stubs(:tbool).returns('abba')

    assert_equal('abba', reviewed_status(resp))
    assert_not_equal(I18n.t("common.pending"), reviewed_status(resp))
  end

  test "reviewed_status is 'pending' if response has been checked out in the last 10 minutes" do
    resp = FactoryGirl.build(:response)
    resp.checked_out_at = 9.minutes.ago
    self.stubs(:tbool).returns('abba')

    assert_not_equal('abba', reviewed_status(resp))
    assert_equal(I18n.t("common.pending"), reviewed_status(resp))
  end

  test "reviewed_status not 'pending' if response has been checked out over 10 minutes" do
    resp = FactoryGirl.build(:response)
    resp.checked_out_at = 11.minutes.ago
    self.stubs(:tbool).returns('abba')

    assert_equal('abba', reviewed_status(resp))
    assert_not_equal(I18n.t("common.pending"), reviewed_status(resp))
  end
end
