require "spec_helper"

describe QingGroup do
  let(:form) { create(:form, question_types: [['text', 'text', 'text']]) }

  it "should return a list of groups" do
    group = create(:qing_group, form: form, ancestry: form.root_group.id)
    expect(form.child_groups.count).to eq(2)
  end
end
