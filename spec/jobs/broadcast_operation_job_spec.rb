require "rails_helper"

describe BroadcastOperationJob do
  let(:operation) { create(:operation, mission: create(:mission)) }
  let(:broadcast) { create(:broadcast, medium: "sms", recipient_users: [create(:user)]) }

  describe "#perform" do
    it "calls broadcast#deliver" do
      expect(broadcast).to receive(:deliver)
      described_class.perform_now(operation, broadcast)
    end

    context "when Sms::Errors::PartialError is raised" do
      before do
        allow(Sms::Broadcaster).to receive(:deliver).and_raise(Sms::Errors::PartialError)
      end

      it "marks operation as completed" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.completed?).to eq(true)
      end

      it "saves job error report" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.job_error_report).to match(/errors delivering some messages/)
      end
    end

    context "when Sms::Errors::FatalError is raised" do
      before do
        allow(Sms::Broadcaster).to receive(:deliver).and_raise(Sms::Errors::FatalError)
      end

      it "marks operation as failed" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.failed?).to eq(true)
      end

      it "saves job error report" do
        described_class.perform_now(operation, broadcast)
        expect(operation.reload.job_error_report).to match(/for more information/)
      end
    end
  end
end
