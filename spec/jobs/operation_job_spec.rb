# frozen_string_literal: true

require "rails_helper"

# A fake operation job that raises an error if requested.
class TestOperationJob < OperationJob
  def perform(operation, *args)
    raise StandardError if args[0] == :raise
  end
end

describe OperationJob do
  let(:operation) { create(:operation, job_class: subject) }

  describe "#perform" do
    it "marks operation as started" do
      TestOperationJob.perform_now(operation)
      expect(operation.reload.job_started_at).not_to be_nil
    end

    it "marks operation as completed" do
      TestOperationJob.perform_now(operation)
      expect(operation.reload.job_completed_at).not_to be_nil
    end

    context "when unexpected error is raised" do
      # Below we need to catch the error because it gets re-raised in test mode when using perform_now.
      # See OperationJob#operation_raised_error comment for more info.

      it "marks operation as started" do
        expect { TestOperationJob.perform_now(operation, :raise) }.to raise_error(StandardError)
        expect(operation.reload.job_started_at).not_to be_nil
      end

      it "marks operation as failed" do
        expect { TestOperationJob.perform_now(operation, :raise) }.to raise_error(StandardError)
        expect(operation.reload.job_failed_at).not_to be_nil
        expect(operation.reload.job_error_report).not_to be_nil
      end

      it "calls exception notifier" do
        expect(ExceptionNotifier).to receive(:notify_exception).with(StandardError)
        expect { TestOperationJob.perform_now(operation, :raise) }.to raise_error(StandardError)
      end
    end

    # The below test only works if perform_later is used.
    context "when operation gets deleted before job is run" do
      it "exits silently" do
        TestOperationJob.perform_later(operation)
        operation.destroy
        expect(ExceptionNotifier).to receive(:notify_exception).with(ActiveJob::DeserializationError)
        Delayed::Worker.new.work_off
      end
    end
  end
end
