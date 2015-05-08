require 'spec_helper'

describe Questioning do

  it "creation" do
    # creating a protoform with a question should automatically create a questioning
    f = create(:form, :question_types => %w(integer))
    expect(f.questionings[0].class).to eq(Questioning)
  end

  it "set rank" do
    f = create(:form, :question_types => %w(integer decimal))
    expect(f.questionings[0].rank).to eq(1)
    expect(f.questionings[1].rank).to eq(2)
  end

  it "validates conditon" do
    f = create(:form, :question_types => %w(integer decimal))
    assert_raise(ActiveRecord::RecordNotSaved) do
      # not sure why this is raising an exception but no time to find out
      f.questionings.last.condition = Condition.new(:ref_qing => f.questionings.first, :op => nil)
    end
  end

  it "previous" do
    f = create(:form, :question_types => %w(integer decimal integer))
    expect(f.questionings.last.previous).to eq(f.questionings[0..1])
  end

  it "mission should get copied from question on creation" do
    f = create(:form, :question_types => %w(integer), :mission => get_mission)
    expect(f.questionings[0].mission).to eq(get_mission)
  end
end