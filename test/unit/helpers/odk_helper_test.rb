require 'test_helper'

class OdkHelperTest < ActionView::TestCase

  test "#required_value returns true for forms that don't allow incomplete responses" do
    f = FactoryGirl.create(:form, :allow_incomplete => false)

    assert_equal('true()', required_value(f))
  end

  test "#required_value returns ODK select statement for forms that allow incomplete responses" do
    f = FactoryGirl.create(:form, :allow_incomplete => true)

    assert_equal("selected\(/data/#{IR_QUESTION}, 'no')", required_value(f))
  end

end
