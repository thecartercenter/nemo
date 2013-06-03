# encoding: utf-8
require 'test_helper'

class Sms::Adapters::IsmsAdapterTest < ActiveSupport::TestCase
  test "converting accented chars works" do
    assert_not_equal("aaaaaa", "àáâãäå")
    assert_equal("aaa ee 'c'", ActiveSupport::Inflector.transliterate("àáâ éé 'ç'"))
  end
end