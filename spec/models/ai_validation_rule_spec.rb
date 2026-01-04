# frozen_string_literal: true

require "rails_helper"

describe AiValidationRule do
  let(:mission) { get_mission }
  let(:user) { create(:user, mission: mission) }
  let(:rule) { build(:ai_validation_rule, mission: mission, user: user) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(rule).to be_valid
    end

    it "requires a name" do
      rule.name = nil
      expect(rule).not_to be_valid
      expect(rule.errors[:name]).to be_present
    end

    it "requires name to be max 255 characters" do
      rule.name = "a" * 256
      expect(rule).not_to be_valid
      expect(rule.errors[:name]).to be_present
    end

    it "requires a rule_type" do
      rule.rule_type = nil
      expect(rule).not_to be_valid
      expect(rule.errors[:rule_type]).to be_present
    end

    it "requires rule_type to be in RULE_TYPES" do
      rule.rule_type = "invalid_type"
      expect(rule).not_to be_valid
      expect(rule.errors[:rule_type]).to be_present
    end

    it "requires a threshold" do
      rule.threshold = nil
      expect(rule).not_to be_valid
      expect(rule.errors[:threshold]).to be_present
    end

    it "requires threshold to be between 0.0 and 1.0" do
      rule.threshold = 1.5
      expect(rule).not_to be_valid
      expect(rule.errors[:threshold]).to be_present

      rule.threshold = -0.1
      expect(rule).not_to be_valid
      expect(rule.errors[:threshold]).to be_present
    end

    it "requires an ai_model" do
      rule.ai_model = nil
      expect(rule).not_to be_valid
      expect(rule.errors[:ai_model]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a mission" do
      expect(rule).to respond_to(:mission)
      expect(rule.mission).to eq(mission)
    end

    it "belongs to a user" do
      expect(rule).to respond_to(:user)
      expect(rule.user).to eq(user)
    end

    it "has many ai_validation_results" do
      rule.save!
      result = create(:ai_validation_result, ai_validation_rule: rule)
      expect(rule.ai_validation_results).to include(result)
    end

    it "destroys validation results when rule is destroyed" do
      rule.save!
      result = create(:ai_validation_result, ai_validation_rule: rule)
      rule.destroy
      expect(AiValidationResult.find_by(id: result.id)).to be_nil
    end
  end

  describe "scopes" do
    let!(:active_rule) { create(:ai_validation_rule, mission: mission, active: true) }
    let!(:inactive_rule) { create(:ai_validation_rule, mission: mission, active: false) }

    it "scopes active rules" do
      expect(AiValidationRule.active).to include(active_rule)
      expect(AiValidationRule.active).not_to include(inactive_rule)
    end

    it "scopes by rule type" do
      anomaly_rule = create(:ai_validation_rule, :anomaly_detection, mission: mission)
      expect(AiValidationRule.for_rule_type("anomaly_detection")).to include(anomaly_rule)
      expect(AiValidationRule.for_rule_type("anomaly_detection")).not_to include(active_rule)
    end
  end

  describe "#validate_response" do
    let(:form) { create(:form, mission: mission, question_types: %w[integer text]) }
    let(:response) { create(:response, form: form, mission: mission) }
    let(:rule) { create(:ai_validation_rule, mission: mission, user: user) }

    context "when API key is not configured" do
      before do
        allow(ENV).to receive(:[]).and_return(nil)
      end

      it "uses mock response" do
        result = rule.validate_response(response)
        expect(result).to be_a(AiValidationResult)
        expect(result.ai_validation_rule).to eq(rule)
        expect(result.response).to eq(response)
      end
    end

    context "when API key is configured" do
      let(:api_key) { "sk-test-key" }
      let(:mock_service) { instance_double(AiProviders::OpenaiService) }

      before do
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(api_key)
        allow(ENV).to receive(:[]).with("NEMO_OPENAI_API_KEY").and_return(nil)
        allow(AiProviders::OpenaiService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:available?).and_return(true)
        allow(mock_service).to receive(:call_ai_model).and_return({
          confidence: 0.9,
          is_valid: true,
          issues: [],
          suggestions: [],
          explanation: "Test explanation"
        })
      end

      it "calls the AI service" do
        expect(mock_service).to receive(:call_ai_model)
        rule.validate_response(response)
      end

      it "creates a validation result" do
        expect do
          rule.validate_response(response)
        end.to change(AiValidationResult, :count).by(1)
      end
    end
  end

  describe "rule type specific validation methods" do
    let(:form) { create(:form, mission: mission, question_types: %w[integer]) }
    let(:response) { create(:response, form: form, mission: mission) }

    AiValidationRule::RULE_TYPES.each do |rule_type|
      it "responds to validate_#{rule_type.underscore}" do
        rule = create(:ai_validation_rule, rule_type: rule_type, mission: mission, user: user)
        expect(rule).to respond_to(:"validate_#{rule_type.underscore}")
      end
    end
  end

  describe "#active?" do
    it "returns true when active is true" do
      rule.active = true
      expect(rule.active?).to be(true)
    end

    it "returns false when active is false" do
      rule.active = false
      expect(rule.active?).to be(false)
    end
  end
end
