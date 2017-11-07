require "spec_helper"

describe Condition do
  it_behaves_like "has a uuid"

  describe "any_fields_blank?" do
    let(:form) { create(:form, question_types: %w(select_one integer)) }
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

  describe "to_s" do
    context "for numeric ref question" do
      let(:form) { create(:form, question_types: %w(integer)) }
      let(:int_q) { form.questionings.first }
      let(:cond) { Condition.new(ref_qing: int_q, op: "lt", value: "5") }

      it "should work" do
        expect(cond.to_s).to eq "Question #1 is less than 5"
      end

      it "should work when including code" do
        expect(cond.to_s(include_code: true)).to eq "Question #1 #{int_q.code} is less than 5"
      end
    end

    context "for non-numeric ref question" do
      let(:form) { create(:form, question_types: %w(text)) }
      let(:text_q) { form.questionings.first }
      let(:cond) { Condition.new(ref_qing: text_q, op: "eq", value: "foo") }

      it "should work" do
        expect(cond.to_s).to eq "Question #1 is equal to \"foo\""
      end
    end

    context "for multiselect ref question" do
      let(:form) { create(:form, question_types: %w(select_multiple)) }
      let(:sel_q) { form.questionings.first }

      it "positive should work" do
        c = Condition.new(ref_qing: sel_q, op: "inc", option_node: sel_q.option_set.c[1])
        expect(c.to_s).to eq "Question #1 includes \"Dog\""
      end

      it "negation should work" do
        c = Condition.new(ref_qing: sel_q, op: "ninc", option_node: sel_q.option_set.c[1])
        expect(c.to_s).to eq "Question #1 does not include \"Dog\""
      end
    end

    context "for single level select ref question" do
      let(:form) { create(:form, question_types: %w(select_one)) }
      let(:sel_q) { form.questionings.first }

      it "should work" do
        c = Condition.new(ref_qing: sel_q, op: "eq", option_node: sel_q.option_set.c[1])
        expect(c.to_s).to eq "Question #1 is equal to \"Dog\""
      end
    end

    context "for multi level select ref question" do
      let(:form) { create(:form, question_types: %w(multilevel_select_one)) }
      let(:sel_q) { form.questionings.first }

      it "matching first level should work" do
        c = Condition.new(ref_qing: sel_q, op: "eq", option_node: sel_q.option_set.c[0])
        expect(c.to_s).to eq "Question #1 Kingdom is equal to \"Animal\""
      end

      context "matching second level" do
        let(:cond) { Condition.new(ref_qing: sel_q, op: "eq", option_node: sel_q.option_set.c[1].c[0]) }

        it "should work normally" do
          expect(cond.to_s).to eq "Question #1 Species is equal to \"Tulip\""
        end

        it "should work when including code" do
          expect(cond.to_s(include_code: true)).to eq "Question #1 #{sel_q.code} Species is equal to \"Tulip\""
        end
      end
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
    let(:form) { create(:form, question_types: %w(datetime integer)) }
    let(:cond) { Condition.new(ref_qing: form.questionings[0], value: "2013-04-30 2:14:12pm") }

    it "should clean time" do
      cond.valid?
      expect(cond.value).to eq "2013-04-30 14:14:12"
    end
  end

  describe "refable qings" do
    let(:form) { create(:form, question_types: %w(location integer integer integer integer)) }
    let(:cond) { Condition.new(questioning: form.questionings[3]) }

    it "should be correct" do
      expect(cond.refable_qings).to eq form.questionings[1..2]
    end
  end

  describe "applicable operator names" do
    let(:form) { create(:form, question_types: %w(select_one integer)) }
    let(:cond) { Condition.new(ref_qing: form.questionings[0]) }

    it "should be correct" do
      expect(cond.applicable_operator_names).to eq %w(eq neq)
    end
  end

  describe ".check_integrity_after_question_change" do
    let(:form) { create(:form, question_types: %w(select_one integer)) }
    let(:question) { form.c[0].question }
    let!(:cond) { create(:condition, questioning: form.c[1], ref_qing: form.c[0]) }

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
