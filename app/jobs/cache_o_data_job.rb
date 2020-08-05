# frozen_string_literal: true

# Caches OData that may have changed.
class CacheODataJob < ApplicationJob
  # Batches should be sufficiently small to not interfere with user-initiated jobs like Reports.
  # In practice, 100 responses take ~10-30 seconds to cache on a small VM.
  BATCH_SIZE = 500

  # A user-facing Operation should be created if there are so many responses to cache
  # that it's worth tracking progress.
  OPERATION_THRESHOLD = 1000

  # Default to lower-priority queue.
  queue_as :odata

  def perform
    enqueued = Delayed::Job.where("handler LIKE '%job_class: CacheODataJob%'").where(failed_at: nil).count
    # Wait to get called again by the scheduler if something else is already in progress.
    return if enqueued > 1

    create_or_update_operation
    cache_batch

    # Self-enqueue if there are responses left to cache after this batch.
    if Response.exists?(dirty_json: true)
      self.class.set(wait: 1.second).perform_later
    else
      complete_operation
    end
  end

  # This can be invoked synchronously or asynchronously, depending on need.
  def self.cache_response(response, logger: Rails.logger)
    json = Results::ResponseJsonGenerator.new(response).as_json
    # Disable validation for a ~25% performance gain.
    response.update_without_validate!(cached_json: json, dirty_json: false)
    json
  rescue StandardError => e
    logger.debug(
      "Failed to update Response #{response.shortcode}\n" \
      "  Mission: #{response.mission.name}\n" \
      "  Form:    #{response.form.name}\n" \
      "  #{e.message}"
    )
    # Phone home without failing the entire operation.
    ExceptionNotifier.notify_exception(e, data: {shortcode: response.shortcode})
    {error: e.class.name}
  end

  private

  # Update the existing operation, if found;
  # otherwise create an operation only if the number of responses exceeds the threshold.
  def create_or_update_operation
    ongoing = Operation.find_by(job_class: CacheODataOperationJob.name, job_completed_at: nil)
    num_responses = Response.where(dirty_json: true).count
    return if ongoing.nil? && num_responses < OPERATION_THRESHOLD
    ongoing = enqueue_operation if ongoing.nil?
    ongoing.update!(notes: "#{I18n.t('operation.notes.remaining')}: #{num_responses}")
  end

  def enqueue_operation
    operation = Operation.new(
      creator: nil,
      mission: nil,
      job_class: CacheODataOperationJob,
      details: I18n.t("operation.details.cache_odata"),
      job_params: {}
    )
    operation.enqueue
    operation
  end

  def complete_operation
    Operation.where(job_class: CacheODataOperationJob.name, job_completed_at: nil)
      .update(job_completed_at: Time.current, notes: nil)
  end

  def cache_batch
    responses = Response.where(dirty_json: true).limit(BATCH_SIZE)
    responses.each do |response|
      CacheODataJob.cache_response(response, logger: Delayed::Worker.logger)
    end
  end
end
