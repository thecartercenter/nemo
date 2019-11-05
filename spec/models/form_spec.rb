# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
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
#  name                  :string(255)      not null
#  sms_relay             :boolean          default(FALSE), not null
#  smsable               :boolean          default(FALSE), not null
#  standard_copy         :boolean          default(FALSE), not null
#  status                :string           default("draft"), not null
#  status_changed_at     :datetime
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
#  index_forms_on_status              (status)
#
# Foreign Keys
#
#  forms_current_version_id_fkey  (current_version_id => form_versions.id) ON DELETE => nullify ON UPDATE => restrict
#  forms_mission_id_fkey          (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  forms_original_id_fkey         (original_id => forms.id) ON DELETE => nullify ON UPDATE => restrict
#  forms_root_id_fkey             (root_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

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

  describe "status_changed_at" do
    it "should be nil on create" do
      expect(form.status_changed_at).to be_nil
    end

    it "should be updated when form goes live" do
      form.update_status(:live)
      expect(form.status_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it "should be updated when form paused" do
      go_live_and_reset_status_changed_at(save: true)
      form.update_status(:paused)
      expect(form.status_changed_at).to be_within(0.1).of(Time.zone.now)
    end

    it "should not be updated when form saved otherwise" do
      go_live_and_reset_status_changed_at
      form.name = "Something else"
      form.save!
      expect(form.status_changed_at).not_to be_within(5.minutes).of(Time.zone.now)
    end
  end

  describe "odk_download_cache_key", :odk do
    before { go_live_and_reset_status_changed_at }

    it "should be correct" do
      expect(form.odk_download_cache_key).to eq("odk-form/#{form.id}-#{form.status_changed_at}")
    end
  end

  describe "odk_index_cache_key", :odk do
    let(:form2) { create(:form) }

    before do
      go_live_and_reset_status_changed_at(save: true)
      go_live_and_reset_status_changed_at(form: form2, diff: 30.minutes, save: true)
    end

    context "for mission with forms" do
      it "should be correct" do
        expect(Form.odk_index_cache_key(mission: get_mission)).to eq(
          "odk-form-list/mission-#{get_mission.id}/#{form2.status_changed_at.utc.to_s(:cache_datetime)}"
        )
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
        expect(form.root_group.sorted_children.count).to eq(3)
      end

      it "has one subgroup with two children" do
        expect(form.root_group.sorted_children[1].sorted_children.count).to eq(2)
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
          expect([Form.count, FormItem.count, SkipRule.count]).to eq([0, 0, 0])
        end
      end

      it "should work" do
        form.destroy
        expect([Form.count, FormItem.count]).to eq([0, 0])
      end

      it "should work with an smsable form" do
        form.update(smsable: true)
        form.destroy
        expect([Form.count, FormItem.count]).to eq([0, 0])
      end
    end
  end

  describe "destroy" do
    let!(:form) { create(:form, :standard, question_types: %w[text text text]) }
    let!(:form2) { form.replicate(mode: :to_mission, dest_mission: get_mission) }
    let!(:report) { create(:standard_form_report, form: form2) }
    let!(:response) { create(:response, form: form2) }
    let!(:recipient) { create(:user) }

    before do
      # Ensure there are related form version(s) and recipients.
      form2.update_status(:live)
      form2.recipient_users << recipient
    end

    it "destroys cleanly" do
      # Ensure creation went as planned.
      expect(form2.original).to be_present
      expect(form2.versions).not_to be_empty
      expect(form2.form_forwardings).not_to be_empty

      form2.destroy
      expect(FormVersion.count).to be_zero
      expect(Response.count).to be_zero
      expect(FormForwarding.count).to be_zero
      expect(Report::Report.count).to be_zero
      expect(FormItem.where.not(mission: nil).count).to be_zero

      # These should not have been deleted.
      expect { form.reload }.not_to raise_error
      expect { recipient.reload }.not_to raise_error
    end
  end

  describe "questioning" do
    let(:form) { create(:form, mission: mission, question_types: [%w[text long_text], "integer", "decimal"]) }

    it "has the questionings in the right order" do
      expect(form.questionings.count).to eq(4)
      expect(form.questionings.map(&:qtype_name)).to eq(%w[text long_text integer decimal])
    end
  end

  describe "associations" do
    let(:form) do
      Timecop.freeze(-1.minute) do
        create(:form, question_types: ["integer", %w[text text]])
      end
    end
    let(:qing) { form.c[0] }
    let(:qing_group) { form.c[1] }
    let(:q) { form.c[0].question }
    let(:updated_at) { form.updated_at }

    it "updates form when a question is destroyed" do
      q.destroy
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a question is updated" do
      q.update!(maximum: 10)
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a qing group is destroyed" do
      qing_group.destroy
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a qing group is updated" do
      qing_group.update!(group_name: "New group name")
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when qing group is added" do
      QingGroup.create!(form_id: form.id)
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a questioning is updated" do
      qing.update!(rank: 10)
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a display condition is added" do
      form.c[1].c[0].update!(display_conditions_attributes:
        [{left_qing_id: form.c[0].id, op: "eq", value: "5"}])
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a skip rule is added" do
      qing.update!(skip_rules_attributes: [{destination: "end", skip_if: "always"}])
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a constraint is added" do
      qing.update!(constraints_attributes:
        [{conditions_attributes: [{left_qing_id: qing.id, op: "eq", value: "5"}]}])
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a questioning is deleted" do
      qing.destroy
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end

    it "updates form when a questioning is added (covers adding a question)" do
      Questioning.create!(form_id: form.id, question: create(:question))
      updated_form = Form.find(form.id)
      expect(updated_form.updated_at).not_to eq(updated_at)
    end
  end

  def go_live_and_reset_status_changed_at(options = {})
    f = options[:form] || form
    f.update_status(:live)
    f.status_changed_at -= (options[:diff] || 1.hour)
    f.save! if options[:save]
  end
end
