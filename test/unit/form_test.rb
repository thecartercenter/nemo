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
end
