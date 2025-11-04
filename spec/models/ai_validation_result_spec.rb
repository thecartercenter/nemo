# frozen_string_literal: true

require "rails_helper"

describe AiValidationResult do
  let(:mission) { get_mission }
  let(:rule) { create(:ai_validation_rule, mission: mission) }
  let(:form) { create(:form, mission: mission) }
  let(:response) { create(:response, form: form, mission: mission) }
  let(:result) { build(:ai_validation_result, ai_validation_rule: rule, response: response) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(result).to be_valid
    end

    it "requires validation_type" do
      result.validation_type = nil
      expect(result).not_to be_valid
      expect(result.errors[:validation_type]).to be_present
    end

    it "requires confidence_score" do
      result.confidence_score = nil
      expect(result).not_to be_valid
      expect(result.errors[:confidence_score]).to be_present
    end

    it "requires confidence_score to be between 0.0 and 1.0" do
      result.confidence_score = 1.5
      expect(result).not_to be_valid
      expect(result.errors[:confidence_score]).to be_present

      result.confidence_score = -0.1
      expect(result).not_to be_valid
      expect(result.errors[:confidence_score]).to be_present
    end

    it "requires is_valid" do
      result.is_valid = nil
      expect(result).not_to be_valid
      expect(result.errors[:is_valid]).to be_present
    end

    it "requires passed" do
      result.passed = nil
      expect(result).not_to be_valid
      expect(result.errors[:passed]).to be_present
    end
  end

  describe "associations" do
    it "belongs to an ai_validation_rule" do
      expect(result).to respond_to(:ai_validation_rule)
      expect(result.ai_validation_rule).to eq(rule)
    end

    it "belongs to a response" do
      expect(result).to respond_to(:response)
      expect(result.response).to eq(response)
    end
  end

  describe "scopes" do
    let!(:passed_result) { create(:ai_validation_result, ai_validation_rule: rule, response: response, passed: true) }
    let!(:failed_result) { create(:ai_validation_result, :failed, ai_validation_rule: rule, response: response) }

    it "scopes passed results" do
      expect(AiValidationResult.passed).to include(passed_result)
      expect(AiValidationResult.passed).not_to include(failed_result)
    end

    it "scopes failed results" do
      expect(AiValidationResult.failed).to include(failed_result)
      expect(AiValidationResult.failed).not_to include(passed_result)
    end

    it "scopes by validation type" do
      anomaly_result = create(:ai_validation_result, :anomaly_detection, ai_validation_rule: rule, response: response)
      expect(AiValidationResult.by_type("anomaly_detection")).to include(anomaly_result)
      expect(AiValidationResult.by_type("anomaly_detection")).not_to include(passed_result)
    end

    it "scopes high confidence results" do
      high_conf_result = create(:ai_validation_result, :high_confidence, ai_validation_rule: rule, response: response)
      expect(AiValidationResult.high_confidence).to include(high_conf_result)
      expect(AiValidationResult.high_confidence).not_to include(passed_result)
    end

    it "scopes low confidence results" do
      low_conf_result = create(:ai_validation_result, :low_confidence, ai_validation_rule: rule, response: response)
      expect(AiValidationResult.low_confidence).to include(low_conf_result)
      expect(AiValidationResult.low_confidence).not_to include(passed_result)
    end
  end

  describe "#severity" do
    it "returns 'low' for confidence < 0.5" do
      result.confidence_score = 0.4
      expect(result.severity).to eq("low")
    end

    it "returns 'medium' for confidence >= 0.5 and < 0.8" do
      result.confidence_score = 0.7
      expect(result.severity).to eq("medium")
    end

    it "returns 'high' for confidence >= 0.8" do
      result.confidence_score = 0.9
      expect(result.severity).to eq("high")
    end
  end

  describe "#status" do
    it "returns 'passed' when passed is true" do
      result.passed = true
      expect(result.status).to eq("passed")
    end

    it "returns 'warning' when passed is false but confidence >= 0.5" do
      result.passed = false
      result.confidence_score = 0.6
      expect(result.status).to eq("warning")
    end

    it "returns 'failed' when passed is false and confidence < 0.5" do
      result.passed = false
      result.confidence_score = 0.4
      expect(result.status).to eq("failed")
    end
  end

  describe "#formatted_issues" do
    it "formats issues as bullet points" do
      result.issues = ["Issue 1", "Issue 2"]
      expect(result.formatted_issues).to eq("• Issue 1\n• Issue 2")
    end

    it "returns empty string when no issues" do
      result.issues = []
      expect(result.formatted_issues).to eq("")
    end
  end

  describe "#formatted_suggestions" do
    it "formats suggestions as bullet points" do
      result.suggestions = ["Suggestion 1", "Suggestion 2"]
      expect(result.formatted_suggestions).to eq("• Suggestion 1\n• Suggestion 2")
    end

    it "returns empty string when no suggestions" do
      result.suggestions = []
      expect(result.formatted_suggestions).to eq("")
    end
  end

  describe "#summary" do
    it "returns a hash with summary information" do
      result.issues = ["Issue 1"]
      result.suggestions = ["Suggestion 1"]
      summary = result.summary

      expect(summary).to be_a(Hash)
      expect(summary[:rule_name]).to eq(rule.name)
      expect(summary[:validation_type]).to eq(result.validation_type)
      expect(summary[:status]).to eq(result.status)
      expect(summary[:severity]).to eq(result.severity)
      expect(summary[:confidence]).to be_a(Numeric)
      expect(summary[:issues_count]).to eq(1)
      expect(summary[:suggestions_count]).to eq(1)
      expect(summary[:explanation]).to eq(result.explanation)
    end
  end
end
