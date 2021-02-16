# frozen_string_literal: true

require "rails_helper"
require "json"

describe CacheODataJob do
  let(:response) { create(:response) }

  # This spec tests the method that caches the JSON, not the JSON itself
  # (see response_json_generator_spec.rb for that).
  describe "dirty flag" do
    it "caches a response and marks clean" do
      expect(response.dirty_json).to be(true)
      json = described_class.cache_response(response)
      expect(json.to_json).to match(/"ResponseReviewed":false/)
      expect(response.dirty_json).to be(false)
    end

    it "returns error json and marks clean" do
      allow(Results::ResponseJsonGenerator).to receive(:new).and_raise(StandardError)
      expect(response.dirty_json).to be(true)
      json = described_class.cache_response(response)
      expect(json.to_json).to match(/"error":"StandardError"/)
      expect(response.dirty_json).to be(false)
    end
  end

  context "batching" do
    let(:num_responses) { 3 }
    let!(:responses) { create_list(:response, num_responses, dirty_json: true) }

    around do |example|
      old = Delayed::Worker.delay_jobs
      Delayed::Worker.delay_jobs = false
      example.run
      Delayed::Worker.delay_jobs = old
    end

    before do
      stub_const(CacheODataJob, "BATCH_SIZE", 2)
      stub_const(CacheODataJob, "OPERATION_THRESHOLD", 100) # Not testing this here.
      stub_const(CacheODataJob, "NOTES_INTERVAL", 1)

      # Run everything synchronously.
      Delayed::Worker.delay_jobs = false
    end

    it "caches them all" do
      described_class.perform_now
      expect(Response.all.pluck(:dirty_json)).to eq([false] * num_responses)
    end

    it "ignores non-live responses" do
      responses[0].form.update_status("draft")
      responses[1].form.update_status("paused")
      responses[2].form.update_status("live")

      described_class.perform_now
      expect(Response.all.pluck(:dirty_json)).to eq([true, false, false])
    end
  end

  context "operation notes" do
    let(:num_responses) { 2 }
    let!(:responses) { create_list(:response, num_responses, dirty_json: true) }

    before do
      stub_const(CacheODataJob, "BATCH_SIZE", 100) # Not testing this here.
      stub_const(CacheODataJob, "OPERATION_THRESHOLD", 1)
      stub_const(CacheODataJob, "NOTES_INTERVAL", 1)
    end

    it "creates an operation and updates it" do
      expect(Operation.first).to be(nil)
      described_class.perform_now
      expect(Response.all.pluck(:dirty_json)).to eq([false] * num_responses)
      expect(Operation.first.notes).to eq("Remaining: 0")
      expect(Operation.first.job_completed_at).not_to be(nil)
    end
  end
end
