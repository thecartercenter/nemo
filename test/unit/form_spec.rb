require 'spec_helper'

describe Form do

  before do
  end

  it "update ranks" do
    f = create(:form, :question_types => %w(integer integer))

    # reload form to ensure questions are sorted by rank
    f.root_questionings(reload = true)

    # save ID of first questioning
    first_qing_id = f.root_questionings[0].id

    # swap ranks and save
    f.update_ranks(f.root_questionings[0].id => 2, f.root_questionings[1].id => 1)
    f.save!

    # now reload and make sure they're switched
    expect(f.root_questionings(reload = true).last.id).to eq(first_qing_id)
  end

  it "destroy questionings" do
    f = create(:form, :question_types => %w(integer decimal decimal integer))

    # remove the decimal questions
    f.destroy_questionings(f.root_questionings[1..2])
    f.reload

    # make sure they're gone and ranks are ok
    expect(f.root_questionings.count).to eq(2)

    expect(f.root_questionings.map(&:rank)).to eq([1,2])
  end

  it "questionings count should work" do
    f = create(:form, :question_types => %w(integer integer))
    f.reload
    expect(f.root_questionings.count).to eq(2)
  end

  it "all required" do
    f = create(:form, :question_types => %w(integer integer))
    expect(f.all_required?).to eq(false)
    f.root_questionings.each{|q| q.required = true; q.save}
    expect(f.all_required?).to eq(true)
  end

  it "form should create new version for itself when published" do
    f = create(:form)
    expect(f.current_version).to be_nil

    # publish and check again
    f.publish!
    f.reload
    expect(f.current_version.sequence).to eq(1)

    # ensure form_id is set properly on version object
    expect(f.current_version.form_id).to eq(f.id)

    # unpublish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.reload
    expect(f.current_version.code).to eq(old)

    # publish again (shouldn't change)
    old = f.current_version.code
    f.publish!
    f.reload
    expect(f.current_version.code).to eq(old)

    # unpublish, set upgrade flag, and publish (should change)
    old = f.current_version.code
    f.unpublish!
    f.flag_for_upgrade!
    f.publish!
    f.reload
    expect(f.current_version.code).not_to eq(old)

    # unpublish and publish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.publish!
    f.reload
    expect(f.current_version.code).to eq(old)
  end

  it "ranks should be fixed after deleting a question" do
    f = create(:form, :question_types => %w(integer integer integer))
    f.questions[1].destroy
    expect(f.reload.questions.size).to eq(2)
    expect(f.root_questionings.last.rank).to eq(2)
  end

  it "updating ranks improperly should trigger condition ordering error" do
    f = create(:form, :question_types => %w(integer integer integer))
    f.root_questionings[2].condition = build(:condition, :ref_qing => f.root_questionings[0], :op => 'lt', :value => 10)
    f.save!

    # we are specifically testing the update_ranks method here
    q1, q2, q3 = f.root_questionings

    # this one shouldn't raise since q with condition stays last
    f.update_ranks({q1.id => 2, q2.id => 1, q3.id => 3})

    assert_raise(ConditionOrderingError) do
      f.update_ranks({q1.id => 3, q2.id => 2, q3.id => 1})
    end
  end
end
