require "rails_helper"

describe QingGroup do
  let(:form) { create(:form, question_types: [["text", "text", "text"]]) }

  it "should return a list of groups" do
    group = create(:qing_group, form: form, ancestry: form.root_group.id)
    expect(form.child_groups.count).to eq(2)
  end

  it "should allow long hints" do
    group = create(:qing_group, group_hint: Faker::Lorem.characters(255).to_s)
    expect(group).to be_valid
  end

  describe "normalization" do
    it "should remove any group item translations if not repeatable" do
      group = create(:qing_group,
        form: form,
        ancestry: form.root_group.id,
        repeatable: false,
        group_item_name_translations: {en: "Name", fr: "Nom"}
      )
      expect(group.group_item_name_translations).to be_blank
    end

    it "should preserve any group item translations if repeatable" do
      group = create(:qing_group,
        form: form,
        ancestry: form.root_group.id,
        repeatable: true,
        group_item_name_translations: {en: "Name", fr: "Nom"}
      )
      expect(group.group_item_name_translations).to eq("en" => "Name", "fr" => "Nom")
    end
  end
end
