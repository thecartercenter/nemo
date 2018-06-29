require "rails_helper"

describe FormVersioningPolicy do
  include OptionNodeSupport

  before do
    # create three forms
    @forms = create_list(:form, 3)

    # publish and then unpublish the forms so they get versions
    @forms.each{|f| f.publish!; f.unpublish!}

    # get the old version codes for comparison
    save_old_version_codes
  end

  it "adding required question should cause upgrade" do
    # add required question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(form_id: f.id, question_id: q.id, required: true, parent: f.root_group)
    end

    publish_and_check_versions(should_change: true)
  end

  it "adding non-required question should not cause upgrade" do
    # add non-required question to first two forms
    q = FactoryGirl.create(:question)

    # Make form 2 smsable
    @forms[1].smsable = true
    @forms[1].save!

    @forms[0...2].each do |f|
      Questioning.create(form_id: f.id, question_id: q.id, required: false, parent: f.root_group)
    end

    publish_and_check_versions(should_change: false)
  end

  it "removing question from form should only cause upgrade if form is smsable and it is not the last question" do
    # ensure the forms are not smsable
    @forms.each{|f| f.smsable = false; f.save!}

    # add 4 questions to all three forms
    qs = (0...4).map{FactoryGirl.create(:question)}
    @forms.each do |f|
      qs.each do |q|
        f.questions << q
        Questioning.create(form_id: f.id, question_id: q.id, required: false, parent: f.root_group)
      end
      f.save!
    end

    save_old_version_codes

    # now delete the first question from first two forms -- this should not cause a bump b/c form is not smsable
    @forms[0...2].each do |f|
      f.destroy_questionings([f.root_questionings(reload = true).first])
    end
    publish_and_check_versions(should_change: false)

    # now make the form smsable and delete the last question -- still should not get a bump
    @forms.each{|f| f.smsable = true; f.save!}
    @forms[0...2].each do |f|
      f.destroy_questionings([f.root_questionings.last])
    end
    publish_and_check_versions(should_change: false)

    # now delete the first question -- this should cause a bump
    @forms[0...2].each do |f|
      f.destroy_questionings([f.root_questionings.first])
    end

    publish_and_check_versions(should_change: true)
  end

  it "changing question rank should cause upgrade if form smsable" do
    # add two question to first two forms
    q1 = FactoryGirl.create(:question, code: "q1")
    q2 = FactoryGirl.create(:question, code: "q2")
    @forms[0...2].each do |f|
      Questioning.create(form_id: f.id, question_id: q1.id, parent: f.root_group)
      Questioning.create(form_id: f.id, question_id: q2.id, parent: f.root_group)
    end

    save_old_version_codes

    # make forms not smsable
    @forms.each{ |f| f.smsable = false; f.save! }

    # now flip the ranks
    @forms[0..1].each do |f|
      old1 = f.root_questionings.find { |q| q.rank == 1 }
      old2 = f.root_questionings.find { |q| q.rank == 2 }
      old2.move(old2.parent, 1)
    end
    publish_and_check_versions(should_change: false)

    # make forms smsable and try again -- should get a bump
    @forms.each{ |f| f.smsable = true; f.save! }
    @forms[0..1].each do |f|
      old1 = f.root_questionings(true).find { |q| q.rank == 1 }
      old2 = f.root_questionings.find { |q| q.rank == 2 }
      old2.move(old2.parent, 1)
    end
    publish_and_check_versions(should_change: true)
  end

  it "changing question condition should cause upgrade if question required" do
    # add ref question and required question
    q1 = FactoryGirl.create(:question)
    q2 = FactoryGirl.create(:question)
    qings1 = []; qings2 = []
    @forms.each do |f|
      qings1 << Questioning.create!(form_id: f.id, question_id: q1.id, required: true, parent: f.root_group)
      qings2 << Questioning.create!(form_id: f.id, question_id: q2.id, required: true, parent: f.root_group)
    end

    save_old_version_codes

    # add a condition in first 2 forms, should not cause bump
    qings2[0...2].each_with_index do |qing, i|
      qing.reload
      qing.display_conditions.build(ref_qing: qings1[i], op: 'eq', value: '1')
      qing.save!
    end
    publish_and_check_versions(should_change: false)

    save_old_version_codes

    # modify condition, should cause bump
    qings2[0...2].each_with_index do |qing, i|
      qing.reload
      condition = qing.display_conditions.first
      condition.value = '2'
      condition.save!
      qing.save!
    end
    publish_and_check_versions(should_change: true)

    save_old_version_codes

    # destroy condition, should cause bump
    qings2[0...2].each_with_index do |qing, i|
      qing.reload
      qing.display_conditions.destroy_all
      qing.save!
    end
    publish_and_check_versions(should_change: true)

  end

  it "changing question required status should cause upgrade" do
    # add non-required question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(form_id: f.id, question_id: q.id, required: false, parent: f.root_group)
    end

    save_old_version_codes

    # now change questioning type to required
    @forms[0...2].each do |f|
      f.questionings.first.update_attributes(required: true)
    end

    publish_and_check_versions(should_change: true)

    save_old_version_codes

    # now change questioning type back to not required
    @forms[0...2].each do |f|
      f.questionings.first.update_attributes(required: false)
    end

    publish_and_check_versions(should_change: true)
  end

  it "deleting question should cause upgrade if question appeared not at end of an smsable form" do
    # add questions to first two forms
    q1 = FactoryGirl.create(:question)
    q2 = FactoryGirl.create(:question)

    # ensure forms are smsable
    @forms.each{|f| f.smsable = true; f.save!}

    @forms[0...2].each do |f|
      Questioning.create(form_id: f.id, question_id: q1.id, parent: f.root_group)
      Questioning.create(form_id: f.id, question_id: q2.id, parent: f.root_group)
    end

    # reload the question so it knows about its new forms
    q1.reload

    save_old_version_codes

    # destroy the question: should cause bump
    q1.destroy

    publish_and_check_versions(should_change: true)
  end


  it "changing question type should cause upgrade" do
    # add question to first two forms
    q = FactoryGirl.create(:question)
    @forms[0...2].each do |f|
      Questioning.create(form_id: f.id, question_id: q.id)
    end

    # reload the question so it knows about its new forms
    q.reload

    save_old_version_codes

    # now change question type to decimal
    q.update_attributes(qtype_name: "decimal")

    publish_and_check_versions(should_change: true)
  end

  it "updating option set with no changes should not cause upgrade" do
    setup_option_set

    save_old_version_codes

    @os.update_attributes!(no_change_changeset(@os.root_node))

    publish_and_check_versions(should_change: false)
  end

  it "changing option set sms_guide_formatting should cause bump on smsable form" do
    setup_option_set

    @os.forms.each{|f| f.update_attributes(smsable: true)}

    save_old_version_codes

    @os.update_attributes(sms_guide_formatting: "appendix")

    publish_and_check_versions(should_change: true)
  end

  it "adding an option to a set should not cause upgrade on non-smsable form" do
    setup_option_set

    save_old_version_codes

    @os.update_attributes!(additive_changeset(@os.root_node))

    publish_and_check_versions(should_change: false)
  end

  it "adding an option to a set should cause upgrade on smsable form" do
    setup_option_set

    @os.forms.each{|f| f.update_attributes(smsable: true)}

    save_old_version_codes

    @os.update_attributes!(additive_changeset(@os.root_node))

    publish_and_check_versions(should_change: true)
  end

  it "changing option label should not cause an upgrade" do
    setup_option_set

    save_old_version_codes

    # change the option
    @os.options.first.update_attributes!(name_en: "New name")

    publish_and_check_versions(should_change: false)
  end

  it "destroying an option should cause upgrade" do
    setup_option_set

    save_old_version_codes

    @os.options.first.destroy

    publish_and_check_versions(should_change: true)
  end

  it "changing option order should cause upgrade if form smsable" do
    setup_option_set

    @os.forms.each { |f| f.update_attributes(smsable: true) }

    save_old_version_codes

    @os.assign_attributes(reorder_changeset(@os.root_node))
    @os.save!

    publish_and_check_versions(should_change: true)
  end

  it "changing option order should not cause upgrade if form not smsable" do
    setup_option_set

    save_old_version_codes

    @os.update_attributes!(reorder_changeset(@os.root_node))

    publish_and_check_versions(should_change: false)
  end

  it "removing option from option_set should cause upgrade" do
    setup_option_set

    save_old_version_codes

    @os.update_attributes!(removal_changeset(@os.root_node))

    publish_and_check_versions(should_change: true)
  end

  # creates an option set, and a question that has the option set, and adds it to first two forms
  def setup_option_set(options = {})
    @os = FactoryGirl.create(:option_set, multilevel: true)
    @q = FactoryGirl.create(:question, qtype_name: "select_one", option_set: @os)
    @forms[0...2].each do |f|
      FactoryGirl.create(:questioning, form: f, question: @q)
      f.reload
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

    method = options[:should_change] ? :not_to : :to

    expect(@old_versions[0]).send(method, eq(@forms[0].current_version.code))
    expect(@old_versions[1]).send(method, eq(@forms[1].current_version.code))

    # third form code should never change
    expect(@old_versions[2]).to eq @forms[2].current_version.code
  end
end
