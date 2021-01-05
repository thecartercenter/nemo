# frozen_string_literal: true

require "rails_helper"

describe BroadcastOperationJob do
  let(:operation) { create(:operation, mission: create(:mission)) }
  let(:broadcast) { create(:broadcast, medium: "sms", recipient_users: [create(:user)]) }

  describe "#perform" do
    it "looks up broadcast and calls deliver" do
      broadcast_double = double(deliver: nil, update!: nil)
      expect(Broadcast).to receive(:find).with(broadcast.id).and_return(broadcast_double)
      expect(broadcast_double).to receive(:deliver)
      described_class.perform_now(operation, broadcast_id: broadcast.id)
    end

    it "saves sent_at time" do
      described_class.perform_now(operation, broadcast_id: broadcast.id)
      expect(broadcast.reload.sent_at).not_to be_nil
    end

    context "when PartialError is raised" do
      let(:broadcaster) { double }

      before do
        allow(Sms::Broadcaster).to receive(:new).and_return(broadcaster)
        allow(broadcaster).to receive(:deliver).and_raise(Sms::Adapters::PartialSendError)
      end

      it "marks operation as completed" do
        described_class.perform_now(operation, broadcast_id: broadcast.id)
        expect(operation.reload.completed?).to eq(true)
      end

      it "saves job error report" do
        described_class.perform_now(operation, broadcast_id: broadcast.id)
        expect(operation.reload.job_error_report).to match(/errors delivering some messages/)
      end
    end

    context "when FatalError is raised" do
      let(:broadcaster) { double }

      before do
        allow(Sms::Broadcaster).to receive(:new).and_return(broadcaster)
        allow(broadcaster).to receive(:deliver).and_raise(Sms::Adapters::FatalSendError)
      end

      it "marks operation as failed" do
        described_class.perform_now(operation, broadcast_id: broadcast.id)
        expect(operation.reload.failed?).to eq(true)
      end

      it "saves job error report" do
        described_class.perform_now(operation, broadcast_id: broadcast.id)
        expect(operation.reload.job_error_report).to match(/for more information/)
      end
    end
  end
end
