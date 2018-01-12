require "spec_helper"

describe "form items" do
  let(:user) { create(:user, role_name: "coordinator") }
  let(:form) { create(:form, question_types: ["text", ["text", "text"]]) }
  let(:qing) { form.sorted_children.select{ |c| c.type == "Questioning" }.first }
  let(:qing_group) { form.sorted_children.select { |c| c.type == "QingGroup" }.first }

  before do
    login(user)
  end

  describe "update" do
    context "when valid ancestry" do
      before(:each) do
        put(form_item_path(qing, mode: "m", mission_name: get_mission.compact_name),
          "rank" => 3, "parent_id" => qing_group.id)
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

  describe "normalization" do
    describe "skip_rules" do
      it "should be discarded if totally empty" do
        qing = create(:questioning, skip_rules_attributes: [
          {destination: "end", skip_if: "always"},
          {destination: "", skip_if: "", conditions_attributes: []},
          {destination: "", skip_if: "", conditions_attributes: [{ref_qing_id: "", op: "", value: ""}]}
        ])
        expect(qing.skip_rules.count).to eq 1
        expect(qing.skip_rules[0].destination).to eq "end"
      end
    end
  end

  describe "condition_form" do
    let(:form) { create(:form, :published, question_types: %w(integer text select_one integer text)) }
    let(:qing) { form.c[3] }
    let(:expected_ref_qing_options) do
      form.c[0..3].map do |q|
        {id: q.id, code: q.question.code, rank: q.rank, full_dotted_rank: q.full_dotted_rank}
      end
    end

    context "without ref_qing_id" do
      it "returns json with ref qing id options, no operator options, and no value options" do
        expected = {
          id: nil,
          ref_qing_id: nil,
          op: nil,
          value: nil,
          option_node_id: nil,
          option_set_id: nil,
          form_id: form.id,
          conditionable_id: qing.id,
          conditionable_type: "FormItem",
          operator_options: [],
          refable_qings: expected_ref_qing_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/form-items/condition-form",{
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
          {name:"is equal to", id:"eq" },
          {name:"is less than", id:"lt" },
          {name:"is greater than", id:"gt" },
          {name:"is less than or equal to", id:"leq" },
          {name:"is greater than or equal to", id:"geq" },
          {name:"is not equal to", id:"neq" }
        ]
        expected = {
          id: nil,
          ref_qing_id: form.c[0].id,
          op: nil,
          value: nil,
          option_node_id: nil,
          option_set_id: nil,
          form_id: form.id,
          conditionable_id: qing.id,
          conditionable_type: "FormItem",
          operator_options: expected_operator_options,
          refable_qings: expected_ref_qing_options
        }.to_json
        get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
          {
            ref_qing_id: form.c[0].id,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem"
          }
        expect(response).to have_http_status(200)
        expect(response.body).to eq expected
      end

      context " text value exists" do
        let(:condition) { create(:condition, conditionable: qing, ref_qing: form.c[1], value: "Test") } #ref_qing: form.c[1], op: "eq", value: "Test"}

        it "returns text value" do
          expected_operator_options = [
            {name:"is equal to", id:"eq" },
            {name:"is not equal to", id:"neq" }
          ]
          expected = {
            id: condition.id,
            ref_qing_id: condition.ref_qing.id,
            op: condition.op,
            value: "Test",
            option_node_id: nil,
            option_set_id: nil,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem",
            operator_options: expected_operator_options,
            refable_qings: expected_ref_qing_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
            {
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
            {name:"is equal to", id:"eq" },
            {name:"is not equal to", id:"neq" }
          ]
          expected = {
            id: condition.id,
            ref_qing_id: condition.ref_qing.id,
            op: condition.op,
            value: nil,
            option_node_id: form.c[2].option_set.c[0].id,
            option_set_id: form.c[2].option_set.id,
            form_id: form.id,
            conditionable_id: qing.id,
            conditionable_type: "FormItem",
            operator_options: expected_operator_options,
            refable_qings: expected_ref_qing_options
          }.to_json
          get "/en/m/#{get_mission.compact_name}/form-items/condition-form",
            {
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
