# frozen_string_literal: true

require "rails_helper"

describe OperationJob do
  let(:operation) { create(:operation, job_class: subject) }

  describe "#perform" do
    subject(:operation_job) do
      Class.new(described_class) do
        def perform(operation, *args)
        end
      end
    end

    it "marks operation as started" do
      subject.perform_now(operation)
      expect(operation.reload.job_started_at).to_not(be_nil)
    end

    it "marks operation as completed" do
      subject.perform_now(operation)
      expect(operation.reload.job_completed_at).to_not(be_nil)
    end

    context "when error is raised" do
      subject(:operation_job_with_error) do
        Class.new(described_class) do
          def perform(operation, *args)
            raise StandardError
          end
        end
      end

      before { allow(ExceptionNotifier).to receive(:notify_exception).with(StandardError) }

      it "marks operation as started" do
        subject.perform_now(operation)
        expect(operation.reload.job_started_at).to_not(be_nil)
      end

      it "marks operation as failed" do
        subject.perform_now(operation)
        expect(operation.reload.job_failed_at).to_not(be_nil)
        expect(operation.reload.job_error_report).to_not(be_nil)
      end

      it "calls exception notifier" do
        expect(ExceptionNotifier).to receive(:notify_exception).with(StandardError)
        subject.perform_now(operation)
      end
    end
  end
end
