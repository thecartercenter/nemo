# frozen_string_literal: true

# == Schema Information
#
# Table name: forms
#
#  id                    :uuid             not null, primary key
#  access_level          :string(255)      default("private"), not null
#  allow_incomplete      :boolean          default(FALSE), not null
#  authenticate_sms      :boolean          default(TRUE), not null
#  default_response_name :string
#  downloads             :integer
#  is_standard           :boolean          default(FALSE), not null
#  name                  :string(255)      not null
#  pub_changed_at        :datetime
#  published             :boolean          default(FALSE), not null
#  sms_relay             :boolean          default(FALSE), not null
#  smsable               :boolean          default(FALSE), not null
#  standard_copy         :boolean          default(FALSE), not null
#  upgrade_needed        :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  current_version_id    :uuid
#  mission_id            :uuid
#  original_id           :uuid
#  root_id               :uuid
#
# Indexes
#
#  index_forms_on_current_version_id  (current_version_id)
#  index_forms_on_mission_id          (mission_id)
#  index_forms_on_original_id         (original_id)
#  index_forms_on_root_id             (root_id) UNIQUE
#
# Foreign Keys
#
#  forms_current_version_id_fkey  (current_version_id => form_versions.id) ON DELETE => nullify ON UPDATE => restrict
#  forms_mission_id_fkey          (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  forms_original_id_fkey         (original_id => forms.id) ON DELETE => nullify ON UPDATE => restrict
#  forms_root_id_fkey             (root_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#


require "rails_helper"

describe Form do
  let(:mission) { create(:mission) }
  let(:user) { create(:user) }
  let(:form) { create(:form) }

  context "API User" do
    before do
      form.access_level = "protected"
      form.whitelistings.create(user_id: user.id)
    end

    it "should return true for user in whitelist" do
      expect(form.api_user_id_can_see?(user.id)).to be_truthy
    end

    it "should return false for user not in whitelist" do
      other_user = create(:user)
      expect(form.api_user_id_can_see?(other_user.id)).to be_falsey
    end
  end

  describe "validation" do
    describe "DynamicPatternValidator" do
      let(:form) { build(:form, default_response_name: "Item: calc($Foo + 4) ") }

      it "is hooked up properly" do
        expect(form).to be_invalid
        expect(form.errors[:default_response_name].join).to match(/must surround/)
      end
    end
  end

  describe "pub_changed_at" do
    it "should be nil on create" do
      expect(form.pub_changed_at).to be_nil
    end

    it "should be updated when form published" do
      form.publish!
      expect(form.pub_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it "should be updated when form unpublished" do
      publish_and_reset_pub_changed_at(save: true)
      form.unpublish!
      expect(form.pub_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it "should not be updated when form saved otherwise" do
      publish_and_reset_pub_changed_at
      form.name = "Something else"
      form.save!
      expect(form.pub_changed_at).not_to be_within(5.minutes).of(Time.zone.now)
    end
  end

  describe "odk_download_cache_key", :odk do
    before { publish_and_reset_pub_changed_at }

    it "should be correct" do
      expect(form.odk_download_cache_key).to eq "odk-form/#{form.id}-#{form.pub_changed_at}"
    end
  end

  describe "odk_index_cache_key", :odk do
    let(:form2) { create(:form) }

    before do
      publish_and_reset_pub_changed_at(save: true)
      publish_and_reset_pub_changed_at(form: form2, diff: 30.minutes, save: true)
    end

    context "for mission with forms" do
      it "should be correct" do
        expect(
          Form.odk_index_cache_key(mission: get_mission)
        ).to eq "odk-form-list/mission-#{get_mission.id}/#{form2.pub_changed_at.utc.to_s(:cache_datetime)}"
      end
    end

    context "for mission with no forms" do
      let(:mission2) { create(:mission) }

      before { create(:form, mission: mission2) }

      it "should be correct" do
        expect(
          Form.odk_index_cache_key(mission: mission2)
        ).to eq("odk-form-list/mission-#{mission2.id}/no-pubd-forms")
      end
    end
  end

  context "multiple question types" do
    let(:form) { create(:form, mission: mission, question_types: ["integer", %w[text text], "text"]) }

    describe "root_group" do
      it "has a root group when created from factory" do
        expect(form.root_group).not_to be_nil
      end
    end

    describe "ancestry" do
      it "has 3 children" do
        expect(form.root_group.sorted_children.count).to eq 3
      end

      it "has one subgroup with two children" do
        expect(form.root_group.sorted_children[1].sorted_children.count).to eq 2
      end
    end

    describe "destroy form" do
      let(:qing_group) { form.c[1] }
      let(:qing1) { form.c[0] }
      let(:qing2) { form.c[2] }

      context "forms with associations" do
        before do
          create(:skip_rule, source_item: qing_group, conditions_attributes: [
            {left_qing_id: qing1.id, op: "eq", value: "5"},
            {left_qing_id: qing2.id, op: "eq", value: "fish"}
          ])
        end

        it "should work" do
          form.destroy
          expect([Form.count, FormItem.count, SkipRule.count]).to eq [0, 0, 0]
        end
      end

      it "should work" do
        form.destroy
        expect([Form.count, FormItem.count]).to eq [0, 0]
      end

      it "should work with an smsable form" do
        form.update(smsable: true)
        form.destroy
        expect([Form.count, FormItem.count]).to eq [0, 0]
      end
    end
  end

  describe "destroy_questionings" do
    it "should work" do
      f = create(:form, question_types: %w[integer decimal decimal integer])
      f.destroy_questionings(f.root_questionings[1..2])
      f.reload

      # make sure they're gone and ranks are ok
      expect(f.root_questionings.count).to eq(2)
      expect(f.root_questionings.map(&:rank)).to eq([1, 2])
    end
  end

  describe "questioning" do
    let(:form) { create(:form, mission: mission, question_types: [%w[text long_text], "integer", "decimal"]) }

    it "has the questionings in the right order" do
      expect(form.questionings.count).to eq(4)
      expect(form.questionings.map(&:qtype_name)).to eq(%w[text long_text integer decimal])
    end
  end

  def publish_and_reset_pub_changed_at(options = {})
    f = options[:form] || form
    f.publish!
    f.pub_changed_at -= (options[:diff] || 1.hour)
    f.save! if options[:save]
  end
end
