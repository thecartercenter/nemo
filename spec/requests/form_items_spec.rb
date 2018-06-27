require "rails_helper"

describe "form items" do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:form) { create(:form, question_types: ["text", %w[text text]]) }
  let(:qing) { form.sorted_children.select { |c| c.type == "Questioning" }.first }
  let(:qing_group) { form.sorted_children.select { |c| c.type == "QingGroup" }.first }

  before do
    login(user)
  end

  describe "update" do
    context "when valid ancestry" do
      before(:each) do
        put(form_item_path(qing, mode: "m", mission_name: get_mission.compact_name),
          params: {"rank" => 3, "parent_id" => qing_group.id})
      end

      it "should be successful" do
        expect(response).to be_success
      end

      it "should update rank and ancestry" do
        params = controller.params
        expect(params[:rank]).to eq "3"
        expect(params[:parent_id]).to eq qing_group.id.to_s
      end
    end
  end

  describe "condition_form" do
    let(:form) { create(:form, :published, question_types: %w[integer text select_one integer text]) }
    let(:qing) { form.c[3] }
    let(:expected_ref_qing_options) do
      form.c[0..3].map do |q|
        {id: q.id, code: q.question.code, rank: q.rank, fullDottedRank: q.full_dotted_rank}
      end
    end

    context "without ref_qing_id" do
      it "returns json with ref qing id options, no operator options, and no value options" do
        expected = {
          id: nil,
          refQingId: nil,
          op: nil,
          value: nil,
          optionNodeId: nil,
          optionSetId: nil,
          formId: form.id,
          conditionableId: qing.id,
          conditionableType: "FormItem",
          operatorOptions: [],
          refableQings: expected_ref_qing_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
          params: {
            ref_qing_id: nil,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem"
          }
        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end
    end

    context "with ref_qing_id" do
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
          refQingId: form.c[0].id,
          op: nil,
          value: nil,
          optionNodeId: nil,
          optionSetId: nil,
          formId: form.id,
          conditionableId: qing.id,
          conditionableType: "FormItem",
          operatorOptions: expected_operator_options,
          refableQings: expected_ref_qing_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
          params: {
            ref_qing_id: form.c[0].id,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem"
          }
        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end

      context "text value exists" do
        let(:condition) { create(:condition, conditionable: qing, ref_qing: form.c[1], value: "Test") }

        it "returns text value" do
          expected_operator_options = [
            {name: "= equals", id: "eq"},
            {name: "≠ does not equal", id: "neq"}
          ]
          expected = {
            id: condition.id,
            refQingId: condition.ref_qing.id,
            op: condition.op,
            value: "Test",
            optionNodeId: nil,
            optionSetId: nil,
            formId: form.id,
            conditionableId: qing.id,
            conditionableType: "FormItem",
            operatorOptions: expected_operator_options,
            refableQings: expected_ref_qing_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
            params: {
              condition_id: condition.id,
              ref_qing_id: form.c[1].id,
              form_id: form.id,
              conditionable_id: qing.id,
              conditionable_type: "FormItem"
            }
          expect(response).to have_http_status(200)
          expect(response.body).to eq expected
        end
      end

      context "option node value exists" do
        let(:condition) { create(:condition, conditionable: qing, ref_qing: form.c[2], value: nil) }

        it "returns text value" do
          expected_operator_options = [
            {name: "= equals", id: "eq"},
            {name: "≠ does not equal", id: "neq"}
          ]
          expected = {
            id: condition.id,
            refQingId: condition.ref_qing.id,
            op: condition.op,
            value: nil,
            optionNodeId: form.c[2].option_set.c[0].id,
            optionSetId: form.c[2].option_set.id,
            formId: form.id,
            conditionableId: qing.id,
            conditionableType: "FormItem",
            operatorOptions: expected_operator_options,
            refableQings: expected_ref_qing_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
            params: {
              condition_id: condition.id,
              ref_qing_id: form.c[2].id,
              form_id: form.id,
              conditionable_id: qing.id,
              conditionable_type: "FormItem"
            }
          expect(response).to have_http_status(200)
          expect(response.body).to eq expected
        end
      end
    end
  end
end
