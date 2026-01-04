# frozen_string_literal: true

require "rails_helper"

describe AiProviders::OpenaiService do
  let(:api_key) { "sk-test-key-12345" }
  let(:model) { "gpt-3.5-turbo" }
  let(:service) { AiProviders::OpenaiService.new(api_key: api_key, model: model) }

  describe "#initialize" do
    it "initializes with API key and model" do
      expect(service.api_key).to eq(api_key)
      expect(service.model).to eq(model)
    end

    it "raises error for invalid model" do
      expect do
        AiProviders::OpenaiService.new(api_key: api_key, model: "invalid-model")
      end.to raise_error(ArgumentError)
    end

    it "accepts valid models" do
      %w[gpt-3.5-turbo gpt-4 gpt-4-turbo gpt-4o].each do |valid_model|
        expect do
          AiProviders::OpenaiService.new(api_key: api_key, model: valid_model)
        end.not_to raise_error
      end
    end
  end

  describe "#available?" do
    it "returns true when API key is present" do
      expect(service.available?).to be(true)
    end

    it "returns false when API key is blank" do
      service_no_key = AiProviders::OpenaiService.new(api_key: "", model: model)
      expect(service_no_key.available?).to be(false)
    end
  end

  describe "#call_ai_model" do
    let(:prompt) { "Test prompt" }
    let(:mock_response) do
      {
        "choices" => [{
          "message" => {
            "content" => {
              "confidence" => 0.9,
              "is_valid" => true,
              "issues" => [],
              "suggestions" => [],
              "explanation" => "Test explanation"
            }.to_json
          }
        }],
        "usage" => {
          "prompt_tokens" => 10,
          "completion_tokens" => 20
        }
      }
    end

    context "with successful API response" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 200,
            body: mock_response.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "calls the OpenAI API" do
        result = service.call_ai_model(prompt)
        expect(result).to be_a(Hash)
        expect(result[:confidence]).to eq(0.9)
        expect(result[:is_valid]).to be(true)
      end

      it "includes usage information" do
        result = service.call_ai_model(prompt)
        expect(result[:usage]).to be_present
      end
    end

    context "with API error" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
            status: 401,
            body: {error: {message: "Invalid API key"}}.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "raises ServiceError" do
        expect do
          service.call_ai_model(prompt)
        end.to raise_error(AiProviders::ServiceError)
      end
    end

    context "with timeout" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_timeout
      end

      it "raises TimeoutError" do
        expect do
          service.call_ai_model(prompt)
        end.to raise_error(AiProviders::TimeoutError)
      end
    end

    context "with connection error" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_raise(SocketError.new("Connection refused"))
      end

      it "raises ConnectionError" do
        expect do
          service.call_ai_model(prompt)
        end.to raise_error(AiProviders::ConnectionError)
      end
    end
  end

  describe "#estimate_cost" do
    it "calculates cost for gpt-3.5-turbo" do
      cost = service.estimate_cost(1000, 500)
      expect(cost).to be > 0
    end

    it "calculates cost for gpt-4" do
      gpt4_service = AiProviders::OpenaiService.new(api_key: api_key, model: "gpt-4")
      cost = gpt4_service.estimate_cost(1000, 500)
      expect(cost).to be > 0
    end

    it "uses default pricing for unknown models" do
      unknown_service = AiProviders::OpenaiService.new(api_key: api_key, model: "gpt-3.5-turbo")
      allow(unknown_service).to receive(:model).and_return("unknown-model")
      cost = unknown_service.estimate_cost(1000, 500)
      expect(cost).to be > 0
    end
  end

  describe "error handling" do
    it "handles malformed JSON response" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(
          status: 200,
          body: {
            "choices" => [{
              "message" => {
                "content" => "Invalid JSON response"
              }
            }]
          }.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = service.call_ai_model("test")
      expect(result).to be_a(Hash)
      expect(result[:confidence]).to eq(0.5) # Fallback value
    end
  end
end
