# frozen_string_literal: true

require "rails_helper"

# A fake operation job that raises an error if requested and writes the timezone to the DB.
class TestOperationJob < OperationJob
  def perform(operation, *args)
    raise StandardError if args[0] == :raise
    operation.update!(details: "The time zone is #{Time.zone}")
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

    context "with funky mission timezone" do
      before do
        operation.mission.setting.update!(timezone: "Newfoundland")
      end

      it "uses appropriate timeonze" do
        TestOperationJob.perform_now(operation)
        expect(operation.details).to eq("The time zone is (GMT-03:30) Newfoundland")
      end
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
        expect(ExceptionNotifier).to receive(:notify_exception).at_least(:once).with(StandardError)
        expect { TestOperationJob.perform_now(operation, :raise) }.to raise_error(StandardError)
      end
    end

    context "when operation gets deleted before job is run" do
      it "raises error" do
        serialized = TestOperationJob.new(operation).serialize
        operation.destroy

        # The .execute method is what AJ calls internally to run a deserialized job.
        # We can't test this functionality by using perform_now because we can't destroy the operation
        # between when the job is enqueued and when it is run in that case.
        # We tried using perform_later and Delayed::Worker.new.work_off. This did not work on CI
        # for unknown reasons.
        expect { TestOperationJob.execute(serialized) }.to raise_error(ActiveJob::DeserializationError)
      end
    end
  end
end
