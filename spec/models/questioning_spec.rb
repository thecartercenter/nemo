require 'spec_helper'

describe Questioning do
  it_behaves_like "has a uuid"

  it "previous" do
    f = create(:form, :question_types => %w(integer decimal integer))
    expect(f.questionings.last.previous).to eq(f.questionings[0..1])
  end

  it "mission should get copied from question on creation" do
    f = create(:form, :question_types => %w(integer), :mission => get_mission)
    expect(f.questionings[0].mission).to eq(get_mission)
  end
end
