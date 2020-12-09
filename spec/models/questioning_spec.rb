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

describe Questioning do
  it "mission should get copied from question on creation" do
    f = create(:form, question_types: %w[integer], mission: get_mission)
    expect(f.questionings[0].mission).to eq(get_mission)
  end

  describe "normalization" do
    # Run valid? to trigger normalization
    let(:q_attrs) { {} }
    let(:question) { create(:question, q_attrs) }
    let(:qing) { build(:questioning, submitted.merge(question: question)).tap(&:valid?) }
    subject { submitted.keys.index_with { |k| qing.send(k) }.to_h }

    describe "hidden/disabled/required/read_only" do
      context do
        let(:submitted) { {hidden: true, disabled: false, required: true, read_only: false} }
        it { is_expected.to eq(hidden: true, disabled: false, required: false, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: false, disabled: true, required: true, read_only: false} }
        it { is_expected.to eq(hidden: false, disabled: true, required: true, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: true, disabled: true, required: false, read_only: false} }
        it { is_expected.to eq(hidden: true, disabled: true, required: false, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: false, disabled: false, required: true, read_only: false} }
        it { is_expected.to eq(hidden: false, disabled: false, required: true, read_only: false) }
      end

      context do
        let(:submitted) { {hidden: false, disabled: false, required: true, read_only: true} }
        it { is_expected.to eq(hidden: false, disabled: false, required: false, read_only: true) }
      end

      context do
        let(:submitted) { {hidden: false, disabled: false, required: false, read_only: true} }
        it { is_expected.to eq(hidden: false, disabled: false, required: false, read_only: true) }
      end
    end

    describe "preload_last_saved and default" do
      context do
        let(:submitted) { {preload_last_saved: false, default: "foo"} }
        it { is_expected.to eq(preload_last_saved: false, default: "foo") }
      end

      context do
        let(:submitted) { {preload_last_saved: true, default: "foo"} }
        it { is_expected.to eq(preload_last_saved: true, default: nil) }
      end
    end

    describe "question metadata and hidden/disabled/required" do
      context do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {required: true, hidden: false, disabled: false} }
        it { is_expected.to eq(required: false, hidden: true, disabled: false) }
      end

      context do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {required: "", hidden: true, disabled: true} }
        it { is_expected.to eq(required: false, hidden: true, disabled: true) }
      end

      context do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: ""} }
        let(:submitted) { {required: true, disabled: false} }
        it { is_expected.to eq(required: true, disabled: false) }
      end
    end

    describe "question metadata and condition" do
      let(:condition) { build(:condition) }

      context "not adding a metadata_type" do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: nil} }
        let(:submitted) { {display_conditions: [condition]} }
        it "should not destroy existing conditions" do
          is_expected.to eq(display_conditions: [condition])
        end
      end

      context "add a metadata_type with an existing condition" do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {display_conditions: [condition]} }
        it "should destroy existing conditions" do
          is_expected.to eq(display_conditions: [])
          expect(condition).to be_destroyed
        end
      end

      context "add a metadata_type with no existing conditions" do
        let(:q_attrs) { {qtype_name: "datetime", metadata_type: "formstart"} }
        let(:submitted) { {display_conditions: []} }
        it "should not change the display conditions" do
          is_expected.to eq(display_conditions: [])
        end
      end
    end

    describe "all_levels_required" do
      let(:question) { form.c[0].question }

      context "multilevel, required question" do
        let(:form) { create(:form, question_types: %w[multilevel_select_one]) }
        let(:submitted) { {all_levels_required: true, required: true} }
        it "should leave all_levels_required alone" do
          is_expected.to eq(all_levels_required: true, required: true)
        end
      end

      context "multilevel, non-required question" do
        let(:form) { create(:form, question_types: %w[multilevel_select_one]) }
        let(:submitted) { {all_levels_required: true, required: false} }
        it "should reset all_levels_required" do
          is_expected.to eq(all_levels_required: false, required: false)
        end
      end

      context "non-multilevel question" do
        let(:form) { create(:form, question_types: %w[select_one]) }
        let(:submitted) { {all_levels_required: true, required: true} }
        it "should reset all_levels_required" do
          is_expected.to eq(all_levels_required: false, required: true)
        end
      end

      context "non-select question" do
        let(:form) { create(:form, question_types: %w[integer]) }
        let(:submitted) { {all_levels_required: true, required: true} }
        it "should reset all_levels_required" do
          is_expected.to eq(all_levels_required: false, required: true)
        end
      end
    end
  end

  describe "validation" do
    let(:questioning) { build(:questioning, default: "Item: calc($Foo + 4) ") }

    # Detailed testing of this validator is in own file.
    describe "DynamicPatternValidator" do
      it "is hooked up properly" do
        expect(questioning).to be_invalid
        expect(questioning.errors[:default].join).to match(/must surround/)
      end
    end

    it "should fail properly when there is no qtype" do
      questioning.qtype_name = nil
      expect { questioning.save }.not_to raise_error
    end
  end
end
