# frozen_string_literal: true

require "rails_helper"

describe "condition form data" do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:form) { create(:form, question_types: ["text", %w[text text]]) }
  let(:qing) { form.c[0] }
  let(:qing_group) { form.c[1] }

  before do
    login(user)
  end

  describe "condition_form" do
    let(:form) { create(:form, :live, question_types: %w[integer text select_one integer text]) }
    let(:qing) { form.c[3] }
    let(:expected_left_qing_options) do
      form.c[0..3].map do |q|
        {id: q.id, code: q.question.code, rank: q.rank, fullDottedRank: q.full_dotted_rank}
      end
    end

    context "without left_qing_id" do
      it "returns json with ref qing id options, no operator options, and no value options" do
        expected = {
          id: nil,
          leftQingId: nil,
          rightQingId: nil,
          rightSideType: "literal",
          op: nil,
          value: nil,
          optionNodeId: nil,
          optionSetId: nil,
          formId: form.id,
          conditionableId: qing.id,
          conditionableType: "FormItem",
          operatorOptions: []
        }.to_json
        get "/en/m/#{get_mission.compact_name}/condition-form-data/base",
          params: {
            left_qing_id: nil,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem"
          }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected)
      end
    end

    context "with left_qing_id" do
      it "returns json with operator options" do
        expected_operator_options = [
          {name: "= equals", id: "eq"},
          {name: "< less than", id: "lt"},
          {name: "> greater than", id: "gt"},
          {name: "≤ less than or equal to", id: "leq"},
          {name: "≥ greater than or equal to", id: "geq"},
          {name: "≠ does not equal", id: "neq"}
        ]
        expected = {
          id: nil,
          leftQingId: form.c[0].id,
          rightQingId: nil,
          rightSideType: "literal",
          op: nil,
          value: nil,
          optionNodeId: nil,
          optionSetId: nil,
          formId: form.id,
          conditionableId: qing.id,
          conditionableType: "FormItem",
          operatorOptions: expected_operator_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/condition-form-data/base",
          params: {
            left_qing_id: form.c[0].id,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem"
          }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected)
      end

      context "text value exists" do
        let(:condition) { create(:condition, conditionable: qing, left_qing: form.c[1], value: "Test") }

        it "returns text value" do
          expected_operator_options = [
            {name: "= equals", id: "eq"},
            {name: "≠ does not equal", id: "neq"}
          ]
          expected = {
            id: condition.id,
            leftQingId: condition.left_qing.id,
            rightQingId: nil,
            rightSideType: "literal",
            op: condition.op,
            value: "Test",
            optionNodeId: nil,
            optionSetId: nil,
            formId: form.id,
            conditionableId: qing.id,
            conditionableType: "FormItem",
            operatorOptions: expected_operator_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/condition-form-data/base",
            params: {
              condition_id: condition.id,
              left_qing_id: form.c[1].id,
              form_id: form.id,
              conditionable_id: qing.id,
              conditionable_type: "FormItem"
            }
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end

      context "option node value exists" do
        let(:condition) { create(:condition, conditionable: qing, left_qing: form.c[2], value: nil) }

        it "returns text value" do
          expected_operator_options = [
            {name: "= equals", id: "eq"},
            {name: "≠ does not equal", id: "neq"}
          ]
          expected = {
            id: condition.id,
            leftQingId: condition.left_qing.id,
            rightQingId: nil,
            rightSideType: "literal",
            op: condition.op,
            value: nil,
            optionNodeId: form.c[2].option_set.c[0].id,
            optionSetId: form.c[2].option_set.id,
            formId: form.id,
            conditionableId: qing.id,
            conditionableType: "FormItem",
            operatorOptions: expected_operator_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/condition-form-data/base",
            params: {
              condition_id: condition.id,
              left_qing_id: form.c[2].id,
              form_id: form.id,
              conditionable_id: qing.id,
              conditionable_type: "FormItem"
            }
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq(expected)
        end
      end
    end
  end
end
