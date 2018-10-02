require "rails_helper"

describe OperationJob do

  let(:operation) { create(:operation,
                           job_class: subject,
                           job_id: nil,
                           job_started_at: nil,
                           job_completed_at: nil) }


  describe "#perform" do
    context "no errors" do
      subject do
        Class.new(described_class) do
          def perform
          end
        end
      end

      it "marks operation as started" do
        subject.perform_now(operation)
        expect(operation.reload.job_started_at).to_not be_nil
      end

      it "marks operation as completed" do
        subject.perform_now(operation)
        expect(operation.reload.job_completed_at).to_not be_nil
      end
    end

    context "raises error" do
      subject do
        Class.new(described_class) do
          def perform
            raise StandardError
          end
        end
      end

      before { allow(ExceptionNotifier).to receive(:notify_exception).with(StandardError) }

      it "marks operation as started" do
        subject.perform_now(operation)
        expect(operation.reload.job_started_at).to_not be_nil
      end

      it "marks operation as failed" do
        subject.perform_now(operation)
        expect(operation.reload.job_failed_at).to_not be_nil
        expect(operation.reload.job_error_report).to_not be_nil
      end

      it "calls exception notifier" do
        expect(ExceptionNotifier).to receive(:notify_exception).with(StandardError)
        subject.perform_now(operation)
      end
    end
  end
end
