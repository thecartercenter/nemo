# == Schema Information
#
# Table name: conditions
#
#  id                 :uuid             not null, primary key
#  conditionable_type :string           not null
#  op                 :string(255)      not null
#  rank               :integer          not null
#  value              :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  conditionable_id   :uuid             not null
#  mission_id         :uuid
#  option_node_id     :uuid
#  ref_qing_id        :uuid             not null
#
# Indexes
#
#  index_conditions_on_conditionable_id                         (conditionable_id)
#  index_conditions_on_conditionable_type_and_conditionable_id  (conditionable_type,conditionable_id)
#  index_conditions_on_mission_id                               (mission_id)
#  index_conditions_on_option_node_id                           (option_node_id)
#  index_conditions_on_ref_qing_id                              (ref_qing_id)
#
# Foreign Keys
#
#  conditions_mission_id_fkey      (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  conditions_option_node_id_fkey  (option_node_id => option_nodes.id) ON DELETE => restrict ON UPDATE => restrict
#  conditions_ref_qing_id_fkey     (ref_qing_id => form_items.id) ON DELETE => restrict ON UPDATE => restrict
#

require "rails_helper"

describe Condition do
  describe "any_fields_blank?" do
    let(:form) { create(:form, question_types: %w[select_one integer]) }
    let(:option_node_id) { form.questionings[0].option_set.children.first.id }

    it "should be true if missing ref_qing" do
      condition = Condition.new(ref_qing: nil, op: "eq", option_node_id: option_node_id)
      expect(condition.send(:any_fields_blank?)).to be true
    end

    it "should be true if missing operator" do
      condition = Condition.new(ref_qing: form.questionings[0], op: nil, option_node_id: option_node_id)
      expect(condition.send(:any_fields_blank?)).to be true
    end

    it "should be true if missing option node" do
      condition = Condition.new(ref_qing: form.questionings[0], op: "eq", option_node_id: nil)
      expect(condition.send(:any_fields_blank?)).to be true
    end

    it "should be true if missing value" do
      condition = Condition.new(ref_qing: form.questionings[1], op: "eq", value: nil)
      expect(condition.send(:any_fields_blank?)).to be true
    end

    it "should be false if option node given" do
      condition = Condition.new(ref_qing: form.questionings[0], op: "eq", option_node_id: option_node_id)
      expect(condition.send(:any_fields_blank?)).to be false
    end

    it "should be false if value given" do
      condition = Condition.new(ref_qing: form.questionings[1], op: "eq", value: "5")
      expect(condition.send(:any_fields_blank?)).to be false
    end
  end

  describe "clear blanks" do
    let(:cond) { Condition.new(op: "eq", value: "  ") }

    it "should clear blanks" do
      cond.valid?
      expect(cond.value).to be_nil
    end
  end

  describe "clean times" do
    let(:form) { create(:form, question_types: %w[datetime integer]) }
    let(:cond) { Condition.new(ref_qing: form.questionings[0], value: "2013-04-30 2:14:12pm") }

    it "should clean time" do
      cond.valid?
      expect(cond.value).to eq "2013-04-30 14:14:12"
    end
  end

  describe "#applicable_operator_names" do
    let(:form) { create(:form, question_types: [qtype] << "integer") }
    let(:cond) { Condition.new(ref_qing: form.questionings[0]) }

    context "for select_one question" do
      let(:qtype) { "select_one" }

      it "should be correct" do
        expect(cond.applicable_operator_names).to eq %i[eq neq]
      end
    end

    context "for textual question" do
      let(:qtype) { "barcode" }

      it "should be correct" do
        expect(cond.applicable_operator_names).to eq %i[eq neq]
      end
    end

    context "for numeric question" do
      let(:qtype) { "decimal" }

      it "should be correct" do
        expect(cond.applicable_operator_names).to eq %i[eq lt gt leq geq neq]
      end
    end

    context "for temporal question" do
      let(:qtype) { "datetime" }

      it "should be correct" do
        expect(cond.applicable_operator_names).to eq %i[eq lt gt leq geq neq]
      end
    end

    context "for select multiple question" do
      let(:qtype) { "select_multiple" }

      it "should be correct" do
        expect(cond.applicable_operator_names).to eq %i[inc ninc]
      end
    end
  end

  describe ".check_integrity_after_question_change" do
    let(:form) { create(:form, question_types: %w[select_one integer]) }
    let(:question) { form.c[0].question }
    let!(:cond) { create(:condition, conditionable: form.c[1], ref_qing: form.c[0]) }

    it "should delete the condition on option set change" do
      question.update!(option_set: create(:option_set))
      expect(Condition.exists?(cond.id)).to be false
    end

    it "should delete the condition on question destroy" do
      question.destroy
      expect(Condition.exists?(cond.id)).to be false
    end
  end
end
