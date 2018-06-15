# frozen_string_literal: true

require "rails_helper"

# Using request spec b/c Authlogic won't work with controller spec
describe "responses", type: :request do
  let!(:form) { create(:form, :published, question_types: %w[integer multilevel_select_one]) }
  let!(:option_set) { OptionSet.first }
  let!(:plants) { option_set.root_node.children.detect { |c| c.option_name == "Plant" } }
  let!(:plant) { plants.option }
  let!(:tulip) { plants.children.detect { |c| c.option_name == "Tulip" }.option }
  let!(:oak) { plants.children.detect { |c| c.option_name == "Oak" }.option }
  let!(:user) { get_user }
  let(:integer_qing) { form.questionings.detect { |qing| qing.qtype_name == "integer" } }
  let(:select_qing) {  form.questionings.detect { |qing| qing.qtype_name == "select_one" } }
  let(:response_attrs) do
    {
      user_id: user.id,
      form_id: form.id,
      answers_attributes: {
        "0" => {
          questioning_id: integer_qing.id,
          relevant: "1",
          value: "42"
        },
        "1" => {
          questioning_id: select_qing.id,
          relevant: "1",
          option_id: plant.id,
          rank: 1
        },
        "2" => {
          questioning_id: select_qing.id,
          relevant: "1",
          option_id: oak.id,
          rank: 2
        }
      }
    }
  end

  before do
    login(user)
  end

  describe "create" do
    it "should work" do
      post(responses_path(mode: "m", mission_name: get_mission.compact_name), params: {response: response_attrs})
      resp = Response.first
      expect(response).to redirect_to responses_path
      expect(resp.user).to eq user
      expect(resp.form).to eq form
      expect(resp.answers.size).to eq 3
    end
  end

  describe "update" do
    let(:resp) { Response.create(response_attrs.merge(mission: get_mission)) }

    it "should work" do
      put(url_for(resp), params: {
        response: response_attrs.merge(
          answers_attributes: {
            "2" => {
              id: resp.answers[2].id,
              relevant: "1",
              option_id: tulip.id,
              rank: 2
            }
          }
        )
      })
      expect(response).to redirect_to(responses_path(mission_name: get_mission.compact_name))
      expect(Response.count).to eq 1
      resp = Response.first
      expect(resp.answers.size).to eq 3
      expect(resp.answers.last.option.name).to eq "Tulip"
    end
  end

  describe "csv", :csv do
    before do
      create(:response, form: form, answer_values: %w[2 Animal])
      create(:response, form: form, answer_values: %w[15 Plant])
    end

    it "should produce valid CSV" do
      get_s(responses_path(mode: "m", mission_name: get_mission.compact_name, format: :csv))
      expect(response.headers["Content-Disposition"]).to match(
        /attachment; filename="elmo-#{get_mission.compact_name}-responses-\d{4}-\d\d-\d\d-\d{4}.csv"/
      )
      result = CSV.parse(response.body)
      expect(result.size).to eq 3 # 2 response rows, 1 header row
      expect(result[1][10]).to eq "Animal"
      expect(result[2][10]).to eq "Plant"
    end
  end
end
