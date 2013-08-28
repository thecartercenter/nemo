require 'test_helper'

class FormTest < ActiveSupport::TestCase
  
  setup do
    clear_objects(Question, Questioning, Form, Form)
  end

  test "name of clone should be correct" do
    assert_equal('My Form', Form.name_of_clone('My Form'))

    FactoryGirl.create(:form, :name => 'My Form')
    assert_equal('My Form (Copy)', Form.name_of_clone('My Form'))
    
    FactoryGirl.create(:form, :name => 'My Form (Copy)')
    assert_equal('My Form (Copy 2)', Form.name_of_clone('My Form'))
    assert_equal('My Form (Copy 2)', Form.name_of_clone('My Form (Copy)'))

    FactoryGirl.create(:form, :name => 'My Form (Copy 2)')
    assert_equal('My Form (Copy 3)', Form.name_of_clone('My Form'))
    assert_equal('My Form (Copy 3)', Form.name_of_clone('My Form (Copy 1)'))
    assert_equal('My Form (Copy 3)', Form.name_of_clone('My Form (Copy 2)'))
  end
  
  test "update ranks" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    
    # reload form to ensure questions are sorted by rank
    f.reload
    
    # save ID of first questioning
    first_qing_id = f.questionings[0].id
    
    # swap ranks and save
    f.update_ranks(f.questionings[0].id.to_s => '2', f.questionings[1].id.to_s => '1')
    f.save!
    
    # now reload and make sure they're switched
    f.reload
    assert_equal(first_qing_id, f.questionings.last.id)
  end

  test "destroy questionings" do
    f = FactoryGirl.create(:form, :question_types => %w(integer decimal decimal integer))
    
    # remove the decimal questions
    f.destroy_questionings(f.questionings[1..2])
    f.reload
    
    # make sure they're gone and ranks are ok
    assert_equal(2, f.questionings.count)
    assert_equal([1,2], f.questionings.map(&:rank))
  end

  test "duplicate" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    
    f2 = f.duplicate
    f2.reload
    
    assert_not_equal(f2.name, f.name)
    
    # should have same questions but different questionings
    assert_equal(f2.questions, f.questions)
    assert_not_equal(f2.questionings, f.questionings)
    assert((f.questionings.map(&:id) & f2.questionings.map(&:id)).empty?, "questionings should have distinct IDs")
  end
  
  test "questionings count should work" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    f.reload
    assert_equal(2, f.questionings_count)
  end

  test "all required" do
    f = FactoryGirl.create(:form, :question_types => %w(integer integer))
    assert_equal(false, f.all_required?)
    f.questionings.each{|q| q.required = true; q.save}
    assert_equal(true, f.all_required?)
  end
  
  test "form should create new version for itself when published" do
    f = FactoryGirl.create(:form)
    assert_nil(f.current_version)
    
    # publish and check again
    f.publish!
    f.reload
    assert_equal(1, f.current_version.sequence)
    
    # ensure form_id is set properly on version object
    assert_equal(f.id, f.current_version.form_id)
    
    # unpublish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.reload
    assert_equal(old, f.current_version.code)
    
    # publish again (shouldn't change)
    old = f.current_version.code
    f.publish!
    f.reload
    assert_equal(old, f.current_version.code)
    
    # unpublish, set upgrade flag, and publish (should change)
    old = f.current_version.code
    f.unpublish!
    f.flag_for_upgrade!
    f.publish!
    f.reload
    assert_not_equal(old, f.current_version.code)
    
    # unpublish and publish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.publish!
    f.reload
    assert_equal(old, f.current_version.code)
  end

  test "replicating form within mission should avoid name conflict" do
    f = FactoryGirl.create(:form, :name => "Myform", :question_types => %w(integer select_one))
    f2 = f.replicate
    assert_equal('Myform (Copy)', f2.name)
    f3 = f2.replicate
    assert_equal('Myform (Copy 2)', f3.name)
    f4 = f3.replicate
    assert_equal('Myform (Copy 3)', f4.name)
  end

  test "replicating form within mission should produce different questionings but same questions and option set" do
    f = FactoryGirl.create(:form, :question_types => %w(integer select_one))
    f2 = f.replicate
    assert_not_equal(f.questionings.first, f2.questionings.first)

    # questionings should point to proper form
    assert_equal(f.questionings[0].form, f)
    assert_equal(f2.questionings[0].form, f2)

    # questions and option sets should be same
    assert_equal(f.questions, f2.questions)
    assert_not_nil(f2.questions[1].option_set)
    assert_equal(f.questions[1].option_set, f2.questions[1].option_set)
  end

  test "replicating form with conditions should produce correct new conditions" do
    f = FactoryGirl.create(:form, :question_types => %w(integer select_one))

    # create condition
    f.questionings[1].condition = FactoryGirl.build(:condition, :ref_qing => f.questionings[0], :op => 'gt', :value => 1)

    # replicate and test
    f2 = f.replicate

    # questionings and conditions should be distinct
    assert_not_equal(f.questionings[1], f2.questionings[1])
    assert_not_equal(f.questionings[1].condition, f2.questionings[1].condition)

    # new condition should point to new questioning
    assert_equal(f2.questionings[1].condition.ref_qing, f2.questionings[0])
  end

  # should not copy some form fields

  # should update condition option_id

  # multiple conditions

end
