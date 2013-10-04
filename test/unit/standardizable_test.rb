require 'test_helper'

class StandardizableTest < ActiveSupport::TestCase

  test "copy_for_mission" do
    o = FactoryGirl.create(:option, :is_standard => true)
    o2 = o.replicate(get_mission)
    assert_equal(o2, o.copy_for_mission(get_mission))
    assert_nil(o.copy_for_mission(nil))
    assert_nil(o.copy_for_mission(FactoryGirl.create(:mission, :name => 'junk')))
  end
  
  test "creating standard form should create standard questions and questionings" do
    # this factory includes some default questions
    f = FactoryGirl.create(:form, :is_standard => true)
    assert(f.reload.questions.all?(&:is_standard?))
    assert(f.questionings.all?(&:is_standard?))
  end

  test "adding questions to a form should create standard questions and questionings" do
    f = FactoryGirl.create(:form, :is_standard => true)
    f.questions << FactoryGirl.create(:question, :is_standard => true)
    assert(f.reload.questions.all?(&:is_standard?))
    assert(f.questionings.all?(&:is_standard?))
  end

  test "std option set should have std optionings and options" do
    os = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no maybe))
    assert(os.reload.optionings.all?(&:is_standard?))
    assert(os.options.all?(&:is_standard?))
    assert(os.optionings.all?(&:is_standard?))
  end

  test "adding options to an std option set should create std options and optionings" do
    f = FactoryGirl.create(:option_set, :is_standard => true)
    f.options << FactoryGirl.create(:option, :is_standard => true)
    assert(f.reload.options.all?(&:is_standard?))
    assert(f.optionings.all?(&:is_standard?))
  end

  # test "deleting option from std option set with copies should replicate properly" do
  #   # setup std option set, question, and form
  #   std_os = FactoryGirl.create(:option_set, :is_standard => true, :option_names => %w(yes no maybe))
  #   std_q = FactoryGirl.create(:question, :qtype_name => 'select_one', :option_set => std_os, :is_standard => true)
  #   std_f = FactoryGirl.create(:form, :is_standard => true)
  #   std_f.questions << std_q

  #   puts std_f.reload.questionings.inspect

  # end

end
