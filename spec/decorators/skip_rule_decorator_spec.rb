# frozen_string_literal: true

require "rails_helper"

describe SkipRuleDecorator do
  describe "human_readable" do
    let!(:form) do
      create(:form,
        name: "Foo",
        question_types: %w[integer integer integer integer integer])
    end
    let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} #{form.c[4].code}" }
    let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} #{form.c[0].code} is equal to 5" }
    let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} #{form.c[1].code} is equal to 10" }

    it "should use OR for any_met" do
      form.c[2].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "any_met",
                                   conditions_attributes: [
                                     {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                     {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                   ])
      skip_rule = form.c[2].skip_rules[0]
      actual = SkipRuleDecorator.new(skip_rule).human_readable
      expected = "SKIP TO #{dest_qing_str} if #{first_cond_str} OR #{second_cond_str}"
      expect(actual).to eq expected
    end

    it "should use AND for all_met" do
      form.c[3].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "all_met",
                                   conditions_attributes: [
                                     {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                     {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                   ])
      skip_rule = form.c[3].skip_rules[0]
      actual = SkipRuleDecorator.new(skip_rule).human_readable
      expected = "SKIP TO #{dest_qing_str} if #{first_cond_str} AND #{second_cond_str}"
      expect(actual).to eq expected
    end

    it "should display properly for skip_if == always" do
      form.c[3].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "always")
      skip_rule = form.c[3].skip_rules[0]
      actual = SkipRuleDecorator.new(skip_rule).human_readable
      expected = "SKIP TO #{dest_qing_str}"
      expect(actual).to eq expected
    end

    it "displays correctly when destination is end of the form" do
      form.c[3].skip_rules.create!(destination: "end", dest_item: nil, skip_if: "all_met",
                                   conditions_attributes: [
                                     {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                     {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                   ])
      skip_rule = form.c[3].skip_rules[0]
      actual = SkipRuleDecorator.new(skip_rule).human_readable
      expected = "SKIP TO end of form if #{first_cond_str} AND #{second_cond_str}"
      expect(actual).to eq expected
    end
  end
end
