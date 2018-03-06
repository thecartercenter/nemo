require "spec_helper"

describe SkipRuleDecorator do
  describe "human_readable" do

    let!(:form) do create(:form,
      name: "Foo",
      question_types: %w[integer integer integer integer integer])
    end

    it "should use OR for any_met" do
      form.c[2].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "any_met",
                                   conditions_attributes: [
                                     {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                     {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                   ])
      skip_rule = form.c[2].skip_rules[0]
      expect(SkipRuleDecorator.new(skip_rule).human_readable).to eq "SKIP TO Question #{form.c[4].full_dotted_rank}. #{form.c[4].name} if Question ##{form.c[0].full_dotted_rank} is equal to 5 OR Question ##{form.c[1].full_dotted_rank} is equal to 10"
    end

    it "should use AND for all_met" do
      form.c[3].skip_rules.create!(destination: "item", dest_item: form.c[4], skip_if: "all_met",
                                   conditions_attributes: [
                                     {ref_qing_id: form.c[0].id, op: "eq", value: "5"},
                                     {ref_qing_id: form.c[1].id, op: "eq", value: "10"}
                                   ])
      skip_rule = form.c[3].skip_rules[0]
      expect(SkipRuleDecorator.new(skip_rule).human_readable).to eq "SKIP TO Question #{form.c[4].full_dotted_rank}. #{form.c[4].name} if Question ##{form.c[0].full_dotted_rank} is equal to 5 AND Question ##{form.c[1].full_dotted_rank} is equal to 10"
    end
  end
end
