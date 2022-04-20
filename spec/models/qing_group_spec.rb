# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: form_items
#
#  id                           :uuid             not null, primary key
#  all_levels_required          :boolean          default(FALSE), not null
#  ancestry                     :text
#  ancestry_depth               :integer          not null
#  default                      :string
#  disabled                     :boolean          default(FALSE), not null
#  display_if                   :string           default("always"), not null
#  group_hint_translations      :jsonb
#  group_item_name_translations :jsonb
#  group_name_translations      :jsonb
#  hidden                       :boolean          default(FALSE), not null
#  one_screen                   :boolean
#  preload_last_saved           :boolean          default(FALSE), not null
#  rank                         :integer          not null
#  read_only                    :boolean
#  repeatable                   :boolean
#  required                     :boolean          default(FALSE), not null
#  type                         :string(255)      not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  form_id                      :uuid             not null
#  form_old_id                  :integer
#  mission_id                   :uuid
#  old_id                       :integer
#  question_id                  :uuid
#  question_old_id              :integer
#
# Indexes
#
#  index_form_items_on_ancestry                 (ancestry)
#  index_form_items_on_form_id                  (form_id)
#  index_form_items_on_form_id_and_question_id  (form_id,question_id) UNIQUE
#  index_form_items_on_mission_id               (mission_id)
#  index_form_items_on_question_id              (question_id)
#
# Foreign Keys
#
#  form_items_form_id_fkey      (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  form_items_mission_id_fkey   (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  form_items_question_id_fkey  (question_id => questions.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

require "rails_helper"

describe QingGroup do
  let(:form) { create(:form, question_types: [%w[text text text]]) }

  it "should return a list of groups" do
    create(:qing_group, form: form, ancestry: form.root_group.id)
    expect(form.child_groups.count).to eq(2)
  end

  it "should allow long hints" do
    group = create(:qing_group, group_hint: Faker::Lorem.characters(number: 255).to_s)
    expect(group).to be_valid
  end

  describe "normalization" do
    it "should remove any group item translations if not repeatable" do
      group = create(:qing_group,
        form: form,
        ancestry: form.root_group.id,
        repeatable: false,
        group_item_name_translations: {en: "Name", fr: "Nom"})
      expect(group.group_item_name_translations).to be_blank
    end

    it "should preserve any group item translations if repeatable" do
      group = create(:qing_group,
        form: form,
        ancestry: form.root_group.id,
        repeatable: true,
        group_item_name_translations: {en: "Name", fr: "Nom"})
      expect(group.group_item_name_translations).to eq("en" => "Name", "fr" => "Nom")
    end
  end
end
