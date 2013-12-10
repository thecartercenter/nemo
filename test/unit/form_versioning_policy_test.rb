require 'test_helper'

class FormVersioningPolicyTest < ActiveSupport::TestCase
  setup do
    # create three forms
    @forms = (0...3).map{ FactoryGirl.create(:form, :published => false) }

    # publish and then unpublish the forms so they get versions
    @forms.each{|f| f.publish!; f.unpublish!}
    
    # get the old version codes for comparison
    save_old_version_codes
  end

  test "adding required question should cause upgrade" do
    # add required question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(:form_id => f.id, :question_id => q.id, :required => true)
    end
    
    publish_and_check_versions(:should_change => true)
  end
  
  test "adding non-required question should not cause upgrade" do
    # add non-required question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(:form_id => f.id, :question_id => q.id, :required => false)
    end
    
    publish_and_check_versions(:should_change => false)
  end

  test "removing question from form should only cause upgrade if form is smsable and it is not the last question" do
    # ensure the forms are not smsable
    @forms.each{|f| f.smsable = false; f.save!}

    # add 4 questions to all three forms
    qs = (0...4).map{FactoryGirl.create(:question)}
    @forms.each do |f|
      qs.each do |q|
        f.questions << q
      end
      f.save!
    end
    
    save_old_version_codes
    
    # now delete the first question from first two forms -- this should not cause a bump b/c form is not smsable
    @forms[0...2].each do |f|
      f.destroy_questionings([f.questionings.first])
    end
    publish_and_check_versions(:should_change => false)

    # now make the form smsable and delete the last question -- still should not get a bump
    @forms.each{|f| f.smsable = true; f.save!}
    @forms[0...2].each do |f|
      f.destroy_questionings([f.questionings.last])
    end
    publish_and_check_versions(:should_change => false)

    # now delete the first question -- this should cause a bump because the ranks will change
    @forms[0...2].each do |f|
      f.destroy_questionings([f.questionings.first])
    end
    publish_and_check_versions(:should_change => true)
  end
  
  test "changing question rank should cause upgrade if form smsable" do
    # add two question to first two forms
    q1 = FactoryGirl.create(:question, :code => "q1")
    q2 = FactoryGirl.create(:question, :code => "q2")
    @forms[0...2].each do |f|
      Questioning.create(:form_id => f.id, :question_id => q1.id)
      Questioning.create(:form_id => f.id, :question_id => q2.id)
    end
    
    save_old_version_codes
    
    # make forms not smsable
    @forms.each{|f| f.smsable = false; f.save!}

    # now flip the ranks
    @forms[0...2].each do |f|
      old1 = f.questionings.find_by_rank(1)
      old2 = f.questionings.find_by_rank(2)
      f.update_ranks({old1.id.to_s => "2", old2.id.to_s => "1"})
      f.save(:validate => false)
    end
    publish_and_check_versions(:should_change => false)

    # make forms smsable and try again -- should get a bump
    @forms.each{|f| f.smsable = true; f.save!}
    @forms[0...2].each do |f|
      old1 = f.questionings.find_by_rank(1)
      old2 = f.questionings.find_by_rank(2)
      f.update_ranks({old1.id.to_s => "2", old2.id.to_s => "1"})
      f.save(:validate => false)
    end
    publish_and_check_versions(:should_change => true)
  end

  test "changing question condition should cause upgrade if question required" do
    # add ref question and required question
    q1 = FactoryGirl.create(:question)
    q2 = FactoryGirl.create(:question)
    qings1 = []; qings2 = []
    @forms.each do |f|
      qings1 << Questioning.create!(:form_id => f.id, :question_id => q1.id, :required => true)
      qings2 << Questioning.create!(:form_id => f.id, :question_id => q2.id, :required => true)
    end

    save_old_version_codes

    # add a condition in first 2 forms, should cause bump
    qings2[0...2].each_with_index do |qing, i|
      qing.reload
      qing.build_condition(:ref_qing => qings1[i], :op => 'eq', :value => '1')
      qing.save!
    end
    publish_and_check_versions(:should_change => true)

    save_old_version_codes

    # modify condition, should cause bump
    qings2[0...2].each_with_index do |qing, i|
      qing.reload
      qing.condition.value = '2'
      qing.save!
    end
    publish_and_check_versions(:should_change => true)

    save_old_version_codes

    # destroy condition, should cause bump
    qings2[0...2].each_with_index do |qing, i|
      qing.reload
      qing.destroy_condition
      qing.save!
    end
    publish_and_check_versions(:should_change => true)

  end

  test "changing question required status should cause upgrade" do
    # add non-required question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(:form_id => f.id, :question_id => q.id, :required => false)
    end
    
    save_old_version_codes
    
    # now change questioning type to required
    @forms[0...2].each do |f|
      f.questionings.first.update_attributes(:required => true)
    end
    
    publish_and_check_versions(:should_change => true)
    
    save_old_version_codes
    
    # now change questioning type back to not required
    @forms[0...2].each do |f|
      f.questionings.first.update_attributes(:required => false)
    end
    
    publish_and_check_versions(:should_change => true)
  end

  test "deleting question should cause upgrade if question appeared not at end of an smsable form" do
    # add questions to first two forms
    q1 = FactoryGirl.create(:question)
    q2 = FactoryGirl.create(:question)

    # ensure forms are smsable
    @forms.each{|f| f.smsable = true; f.save!}

    @forms[0...2].each do |f|
      Questioning.create(:form_id => f.id, :question_id => q1.id)
      Questioning.create(:form_id => f.id, :question_id => q2.id)
    end

    # reload the question so it knows about its new forms
    q1.reload
    
    save_old_version_codes

    # destroy the question: should cause bump
    q1.destroy

    publish_and_check_versions(:should_change => true)
  end


  test "changing question type should cause upgrade" do
    # add question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(:form_id => f.id, :question_id => q.id)
    end
    
    # reload the question so it knows about its new forms
    q.reload
    
    save_old_version_codes
    
    # now change question type to decimal
    q.update_attributes(:qtype_name => "decimal")
    
    publish_and_check_versions(:should_change => true)
  end
  
  test "adding an option to a set should cause upgrade" do
    setup_option_set

    save_old_version_codes
    
    # add an option
    @os.options << Option.new(:name_en => "Troublemaker", :mission => get_mission)
    @os.save!
    
    publish_and_check_versions(:should_change => true)
  end
  
  test "changing option label should not cause an upgrade" do
    setup_option_set

    save_old_version_codes
    
    # change the option
    @os.options.first.update_attributes!(:name_en => "New name")
    
    publish_and_check_versions(:should_change => false)
  end
  
  test "destroying an option should cause upgrade" do
    setup_option_set
    
    save_old_version_codes
    
    # destroy one of the options from os
    Option.find(@os.options.last.id).destroy
    @os.reload
    assert_equal(1, @os.options.size)
    
    publish_and_check_versions(:should_change => true)
  end
  
  test "changing option order should cause upgrade if form smsable" do
    setup_option_set
    
    [true, false].each do |bool|
      @forms.each{|f| f.smsable = bool; f.save!}

      save_old_version_codes
    
      # now change the option order (we move the first optioning to the back)
      @os.reload
      opt_stg = @os.optionings[0]
      old_rank = opt_stg.rank
      opt_stg.rank = 10000 # this will automatically be trimmed
      @os.save!
      
      # verify the rank changed
      assert_not_equal(old_rank, opt_stg.reload.rank)
      
      publish_and_check_versions(:should_change => bool)
    end
  end

  test "removing option from option_set should cause upgrade" do
    setup_option_set
    save_old_version_codes
    
    # now remove an option from the set the option set order
    @os.optionings.delete(@os.optionings.last)
    @os.save
    
    publish_and_check_versions(:should_change => true)
  end
  
  private
    # creates an option set, and a question that has the option set, and adds it to first two forms
    def setup_option_set
      @os = FactoryGirl.create(:option_set)
      @q = FactoryGirl.create(:question, :qtype_name => "select_one", :option_set => @os)
      @forms[0...2].each do |f|
        f.questions << @q
        f.save!
      end
      @os.reload
      @q.reload
    end
  
    # reloads all forms
    def reload_forms
      @forms.each{|f| f.reload}
    end
    
    def save_old_version_codes
      # publish and unpublish so any pending upgrades are performed
      reload_forms
      @forms.each{|f| f.publish!; f.unpublish!}
      reload_forms
      @old_versions = @forms.collect{|f| f.current_version.code}
    end
    
    def publish_and_check_versions(options)
      reload_forms
      
      @forms.each{|f| f.publish!}

      reload_forms
      
      method = options[:should_change] ? "assert_not_equal" : "assert_equal"
      
      send(method, @old_versions[0], @forms[0].current_version.code)
      send(method, @old_versions[1], @forms[1].current_version.code)
      
      # third form code should never change
      assert_equal(@old_versions[2], @forms[2].current_version.code)
    end
end
