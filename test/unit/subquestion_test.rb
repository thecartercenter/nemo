require 'test_helper'

class SubquestionTest < ActiveSupport::TestCase

  test "subquestions should copy mission from parent" do
    os = FactoryGirl.create(:multilevel_option_set)
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => os)
    assert_equal(q.mission, q.subquestions.first.mission)
  end

end