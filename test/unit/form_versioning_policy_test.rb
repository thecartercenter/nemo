require 'test_helper'

class FormVersioningPolicyTest < ActiveSupport::TestCase
  # setup do
  #   [Form, Question, Questioning, Option, OptionSet, Optioning].each{|k| k.delete_all}

  #   # create three forms
  #   @forms = (0...3).collect{ FactoryGirl.create(:form, :published => false) }

  #   # publish and then unpublish the forms so they get versions
  #   @forms.each{|f| f.publish!; f.unpublish!}
    
  #   # get the old version codes for comparison
  #   save_old_version_codes
  # end
  
  # test "adding an option to a set should cause upgrade" do
  #   setup_option_set

  #   save_old_version_codes
    
  #   # add an option
  #   @os.options << Option.new(:name_en => "Troublemaker", :mission => get_mission)
  #   @os.save!
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # test "changing option label should not cause an upgrade" do
  #   setup_option_set

  #   save_old_version_codes
    
  #   # change the option
  #   @os.options.first.update_attributes!(:name_en => "New name")
    
  #   publish_and_check_versions(:should_change => false)
  # end
  
  # test "destroying an option should cause upgrade" do
  #   setup_option_set
    
  #   save_old_version_codes
    
  #   # destroy one of the options from os
  #   Option.find(@os.options.last.id).destroy
  #   @os.reload
  #   assert_equal(1, @os.options.size)
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # test "adding required question should cause upgrade" do
  #   # add required question to first two forms
  #   q = FactoryGirl.create(:question)
  #   @forms[0...2].each do |f|
  #     Questioning.create(:form_id => f.id, :question_id => q.id, :required => true)
  #   end
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # test "adding non-required question should not cause upgrade" do
  #   # add non-required question to first two forms
  #   q = FactoryGirl.create(:question)
  #   @forms[0...2].each do |f|
  #     Questioning.create(:form_id => f.id, :question_id => q.id, :required => false)
  #   end
    
  #   publish_and_check_versions(:should_change => false)
  # end

  # test "changing question required status should cause upgrade" do
  #   # add non-required question to first two forms
  #   q = FactoryGirl.create(:question)
  #   @forms[0...2].each do |f|
  #     Questioning.create(:form_id => f.id, :question_id => q.id, :required => false)
  #   end
    
  #   save_old_version_codes
    
  #   # now change questioning type to required
  #   @forms[0...2].each do |f|
  #     f.questionings.first.update_attributes(:required => true)
  #   end
    
  #   publish_and_check_versions(:should_change => true)
    
  #   save_old_version_codes
    
  #   # now change questioning type back to not required
  #   @forms[0...2].each do |f|
  #     f.questionings.first.update_attributes(:required => false)
  #   end
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # test "changing question rank status should cause upgrade" do
  #   # add two question to first two forms
  #   q1 = FactoryGirl.create(:question, :code => "q1")
  #   q2 = FactoryGirl.create(:question, :code => "q2")
  #   @forms[0...2].each do |f|
  #     Questioning.create(:form_id => f.id, :question_id => q1.id)
  #     Questioning.create(:form_id => f.id, :question_id => q2.id)
  #   end
    
  #   save_old_version_codes
    
  #   # now flip the ranks
  #   @forms[0...2].each do |f|
  #     old1 = f.questionings.find_by_rank(1)
  #     old2 = f.questionings.find_by_rank(2)
  #     f.update_ranks({old1.id.to_s => "2", old2.id.to_s => "1"})
  #     f.save(:validate => false)
  #   end
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # test "removing question from form should NOT cause upgrade if no questions after it" do
  #   # add 2 questions to all three forms
  #   q1 = FactoryGirl.create(:question, :code => "q1")
  #   q2 = FactoryGirl.create(:question, :code => "q2")
  #   @forms.each do |f|
  #     Questioning.create(:form_id => f.id, :question_id => q1.id)
  #     Questioning.create(:form_id => f.id, :question_id => q2.id)
  #   end
    
  #   save_old_version_codes
    
  #   # now delete the second question from first two forms
  #   @forms[0...2].each do |f|
  #     f.destroy_questionings([f.questionings.last])
  #   end
    
  #   publish_and_check_versions(:should_change => false)
  # end
  
  # test "changing question type should cause upgrade" do
  #   # add question to first two forms
  #   q = FactoryGirl.create(:question)
  #   @forms[0...2].each do |f|
  #     Questioning.create(:form_id => f.id, :question_id => q.id)
  #   end
    
  #   # reload the question so it knows about its new forms
  #   q.reload
    
  #   save_old_version_codes
    
  #   # now change question type to decimal
  #   q.update_attributes(:qtype_name => "decimal")
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # test "changing option order should cause upgrade" do
  #   setup_option_set
  #   save_old_version_codes
    
  #   # now change the option order (we move the first optioning to the back)
  #   opt_stg = @os.optionings[0]
  #   old_rank = opt_stg.rank
  #   opt_stg.rank = 10000 # this will automatically be trimmed
  #   @os.save!
    
  #   # verify the rank changed
  #   assert_not_equal(old_rank, opt_stg.reload.rank)
    
  #   publish_and_check_versions(:should_change => true)
  # end

  # test "removing option from option_set should cause upgrade" do
  #   setup_option_set
  #   save_old_version_codes
    
  #   # now remove an option from the set the option set order
  #   @os.optionings.delete(@os.optionings.last)
  #   @os.save
    
  #   publish_and_check_versions(:should_change => true)
  # end
  
  # private
  #   # creates an option set, and a question that has the option set, and adds it to first two forms
  #   def setup_option_set
  #     @os = FactoryGirl.create(:option_set)
  #     @q = FactoryGirl.create(:question, :qtype_name => "select_one", :option_set => @os)
  #     @forms[0...2].each do |f|
  #       f.questions << @q
  #       f.save!
  #     end
  #     @os.reload
  #     @q.reload
  #   end
  
  #   def reload_forms
  #     # reload all forms
  #     @forms.each{|f| f.reload}
  #   end
    
  #   def save_old_version_codes
  #     reload_forms
  #     @old_versions = @forms.collect{|f| f.current_version.code}
  #   end
    
  #   def publish_and_check_versions(options)
  #     reload_forms
      
  #     @forms.each{|f| f.publish!}

  #     reload_forms
      
  #     method = options[:should_change] ? "assert_not_equal" : "assert_equal"
      
  #     send(method, @old_versions[0], @forms[0].current_version.code)
  #     send(method, @old_versions[1], @forms[1].current_version.code)
      
  #     # third form code should never change
  #     assert_equal(@old_versions[2], @forms[2].current_version.code)
  #   end
end
