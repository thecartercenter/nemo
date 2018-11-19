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
      expect(operation.reload.job_started_at).not_to be_nil
    end

    it "marks operation as completed" do
      subject.perform_now(operation)
      expect(operation.reload.job_completed_at).not_to be_nil
    end

    context "when unexpected error is raised" do
      subject(:operation_job_with_error) do
        Class.new(described_class) do
          def perform(_operation, *_args)
            raise StandardError
          end
        end
      end

      before { allow(ExceptionNotifier).to receive(:notify_exception).with(StandardError) }

      # Below we need to catch the error because it gets re-raised in test mode.
      # See OperationJob#operation_raised_error comment for more info.

      it "marks operation as started" do
        expect { subject.perform_now(operation) }.to raise_error(StandardError)
        expect(operation.reload.job_started_at).not_to be_nil
      end

      it "marks operation as failed" do
        expect { subject.perform_now(operation) }.to raise_error(StandardError)
        expect(operation.reload.job_failed_at).not_to be_nil
        expect(operation.reload.job_error_report).not_to be_nil
      end

      it "calls exception notifier" do
        expect(ExceptionNotifier).to receive(:notify_exception).with(StandardError)
        expect { subject.perform_now(operation) }.to raise_error(StandardError)
      end
    end
  end
end
