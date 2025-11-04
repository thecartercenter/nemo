# frozen_string_literal: true

require "rails_helper"

describe "AI Validation", type: :request do
  let(:mission) { get_mission }
  let(:user) { create(:user, role_name: :coordinator, mission: mission) }
  let(:form) { create(:form, mission: mission, question_types: %w[integer text]) }
  let(:response) { create(:response, form: form, mission: mission) }

  before(:each) { login(user) }

  describe "GET /ai-validation-rules" do
    let!(:rule1) { create(:ai_validation_rule, mission: mission, user: user) }
    let!(:rule2) { create(:ai_validation_rule, :inactive, mission: mission, user: user) }

    it "lists all AI validation rules" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(rule1.name)
      expect(response.body).to include(rule2.name)
    end

    it "paginates results" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules?page=1"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /ai-validation-rules/:id" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }
    let!(:result1) { create(:ai_validation_result, ai_validation_rule: rule, response: response) }
    let!(:result2) { create(:ai_validation_result, :failed, ai_validation_rule: rule, response: response) }

    it "shows rule details with validation results" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules/#{rule.id}"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(rule.name)
    end
  end

  describe "GET /ai-validation-rules/new" do
    it "shows new rule form" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /ai-validation-rules" do
    let(:valid_params) do
      {
        ai_validation_rule: {
          name: "New Rule",
          description: "Test description",
          rule_type: "data_quality",
          ai_model: "gpt-3.5-turbo",
          threshold: 0.8,
          active: true
        }
      }
    end

    it "creates a new AI validation rule" do
      expect {
        post "/en/m/#{mission.compact_name}/ai-validation-rules", params: valid_params
      }.to change(AiValidationRule, :count).by(1)

      expect(response).to redirect_to(ai_validation_rule_path(AiValidationRule.last))
    end

    it "renders errors when invalid" do
      valid_params[:ai_validation_rule][:name] = nil
      post "/en/m/#{mission.compact_name}/ai-validation-rules", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /ai-validation-rules/:id/edit" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }

    it "shows edit form" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules/#{rule.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /ai-validation-rules/:id" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }

    it "updates the rule" do
      patch "/en/m/#{mission.compact_name}/ai-validation-rules/#{rule.id}",
            params: { ai_validation_rule: { name: "Updated Name" } }
      expect(response).to redirect_to(ai_validation_rule_path(rule))
      expect(rule.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /ai-validation-rules/:id" do
    let!(:rule) { create(:ai_validation_rule, mission: mission, user: user) }

    it "deletes the rule" do
      expect {
        delete "/en/m/#{mission.compact_name}/ai-validation-rules/#{rule.id}"
      }.to change(AiValidationRule, :count).by(-1)

      expect(response).to redirect_to(ai_validation_rules_path)
    end
  end

  describe "PATCH /ai-validation-rules/:id/toggle_active" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user, active: true) }

    it "toggles active status" do
      expect {
        patch "/en/m/#{mission.compact_name}/ai-validation-rules/#{rule.id}/toggle_active",
              headers: { "Accept" => "application/json" }
      }.to change { rule.reload.active }.from(true).to(false)

      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
      expect(json_response["active"]).to be false
    end
  end

  describe "POST /ai-validation-rules/:id/test_rule" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }

    before do
      allow(ENV).to receive(:[]).and_return(nil) # Use mock
    end

    it "tests the rule against a response" do
      post "/en/m/#{mission.compact_name}/ai-validation-rules/#{rule.id}/test_rule",
           params: { response_id: response.id },
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
      expect(json_response["result"]).to be_present
    end
  end

  describe "POST /ai-validation-rules/validate_response" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user, active: true) }

    before do
      allow(ENV).to receive(:[]).and_return(nil) # Use mock
    end

    it "validates a response against all active rules" do
      post "/en/m/#{mission.compact_name}/ai-validation-rules/validate_response",
           params: { response_id: response.id },
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
      expect(json_response["results"]).to be_an(Array)
    end
  end

  describe "POST /ai-validation-rules/validate_batch" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user, active: true) }
    let!(:response2) { create(:response, form: form, mission: mission) }

    before do
      allow(ENV).to receive(:[]).and_return(nil) # Use mock
    end

    it "validates multiple responses" do
      post "/en/m/#{mission.compact_name}/ai-validation-rules/validate_batch",
           params: { form_ids: [form.id] },
           headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
      expect(json_response["results_count"]).to be >= 0
    end
  end

  describe "GET /ai-validation-rules/report" do
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }
    let!(:result) { create(:ai_validation_result, ai_validation_rule: rule, response: response) }

    it "shows validation report" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules/report"
      expect(response).to have_http_status(:success)
    end

    it "filters by date range" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules/report",
          params: { date_from: 1.month.ago.to_date, date_to: Date.current }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /ai-validation-rules/suggestions" do
    it "returns rule suggestions" do
      get "/en/m/#{mission.compact_name}/ai-validation-rules/suggestions",
          headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
      expect(json_response["suggestions"]).to be_an(Array)
    end
  end

  describe "authorization" do
    let(:enumerator) { create(:user, role_name: :enumerator, mission: mission) }
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }

    context "when user cannot view AI validation" do
      before { login(enumerator) }

      it "denies access to index" do
        get "/en/m/#{mission.compact_name}/ai-validation-rules"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
