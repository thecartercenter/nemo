# frozen_string_literal: true

require "rails_helper"

describe ConstraintDecorator do
  describe "human_readable" do
    let!(:form) do
      create(:form,
        name: "Foo",
        question_types: %w[integer integer integer integer integer])
    end
    let(:dest_qing_str) { "Question ##{form.c[4].full_dotted_rank} [#{form.c[4].code}]" }
    let(:first_cond_str) { "Question ##{form.c[0].full_dotted_rank} [#{form.c[0].code}] is equal to 5" }
    let(:second_cond_str) { "Question ##{form.c[1].full_dotted_rank} [#{form.c[1].code}] is equal to 10" }

    it "should use OR for any_met" do
      form.c[2].constraints.create!(accept_if: "any_met",
                                    conditions_attributes: [
                                      {left_qing_id: form.c[0].id, op: "eq", value: "5"},
                                      {left_qing_id: form.c[1].id, op: "eq", value: "10"}
                                    ])
      constraint = form.c[2].constraints[0]
      actual = ConstraintDecorator.new(constraint).human_readable
      expected = "VALID ONLY IF #{first_cond_str} OR #{second_cond_str}"
      expect(actual).to eq(expected)
    end

    it "should use AND for all_met" do
      form.c[3].constraints.create!(accept_if: "all_met",
                                    conditions_attributes: [
                                      {left_qing_id: form.c[0].id, op: "eq", value: "5"},
                                      {left_qing_id: form.c[1].id, op: "eq", value: "10"}
                                    ])
      constraint = form.c[3].constraints[0]
      actual = ConstraintDecorator.new(constraint).human_readable
      expected = "VALID ONLY IF #{first_cond_str} AND #{second_cond_str}"
      expect(actual).to eq(expected)
    end
  end
end
