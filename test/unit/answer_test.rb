require 'test_helper'

class AnswerTest < ActiveSupport::TestCase

  test "creation should succeed if questionable exists" do
    qing = FactoryGirl.create(:questioning)
    FactoryGirl.create(:answer, :questioning => qing, :questionable => qing.question)
  end

  test "should error if questionable_id doesnt refer to a subquestion and associated question is multilevel" do
    os = FactoryGirl.create(:multilevel_option_set)
    q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => os)
    qing = FactoryGirl.create(:questioning, :question => q)

    exception = assert_raise(RuntimeError){ FactoryGirl.create(:answer, :questioning => qing) }
    assert_match(/questionable must be a subquestion when question is multilevel/, exception.message)
  end

end
