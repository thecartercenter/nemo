require "spec_helper"

describe QingGroup do
  it_behaves_like "has a uuid"

  let(:form) { create(:form, question_types: [["text", "text", "text"]]) }

  it "should return a list of groups" do
    group = create(:qing_group, form: form, ancestry: form.root_group.id)
    expect(form.child_groups.count).to eq(2)
  end

  it "should allow long hints" do
    group = create(:qing_group, group_hint: Faker::Lorem.characters(255).to_s)
    expect(group).to be_valid
  end
end
