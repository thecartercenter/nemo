# frozen_string_literal: true

# Caches OData that may have changed.
class CacheODataJob < ApplicationJob
  # Batches should be sufficiently small to not interfere with user-initiated jobs like Reports.
  # In practice, 100 responses take ~30-200 seconds to cache on a normal VM like `B2s`.
  # It takes just a few milliseconds to transition between each batch.
  BATCH_SIZE = 30

  # A user-facing Operation should be created if there are so many responses to cache
  # that it's worth tracking progress.
  OPERATION_THRESHOLD = 300

  # Frequency at which the Operation.notes should be updated for the user.
  # Has no effect if it's greater than BATCH_SIZE (notes are always updated on new batch).
  NOTES_INTERVAL = 100

  # Default to lower-priority queue.
  queue_as :odata

  # This can be invoked synchronously or asynchronously, depending on need.
  def self.cache_response(response, logger: Rails.logger)
    json = Results::ResponseJsonGenerator.new(response).as_json
    # Disable validation for a ~25% performance gain.
    response.update_without_validate!(cached_json: json, dirty_json: false)
    json
  rescue StandardError => e
    # Phone home without failing the entire operation.
    logger.debug(debug_msg(e, response))
    ExceptionNotifier.notify_exception(e, data: {shortcode: response.shortcode})
    # It didn't get cached due to the error, but it shouldn't remain dirty
    # because the error will recur forever. Let the cached_json remain `nil`.
    response.update_without_validate!(cached_json: nil, dirty_json: false)
    {error: e.class.name}
  end

  def self.debug_msg(error, response)
    "Failed to update Response #{response.shortcode}\n" \
      "  Mission: #{response.mission.name}\n" \
      "  Form:    #{response.form.name}\n" \
      "  #{error.message}"
  end

  def perform
    # Wait to get called again by the scheduler if this job is already in progress.
    return if existing_jobs > 1

    create_or_update_operation
    cache_batch
    loop_or_finish
  end

  private

  def existing_jobs
    Delayed::Job.where("handler LIKE '%job_class: #{self.class.name}%'").where(failed_at: nil).count
  end

  def existing_operation
    Operation.find_by(job_class: CacheODataOperationJob.name, job_completed_at: nil)
  end

  def remaining_responses
    Response.dirty_json.published
  end

  # Update the existing operation, if found;
  # otherwise create an operation only if the number of responses exceeds the threshold.
  def create_or_update_operation
    if existing_operation.nil?
      return if remaining_responses.count < OPERATION_THRESHOLD
      enqueue_operation
    end
    update_notes
  end

  def cache_batch
    responses = remaining_responses
      .order(cached_json: :desc, created_at: :desc)
      .limit(BATCH_SIZE)
    Delayed::Worker.logger.info("Caching batch (#{responses.count})...")
    responses.each_with_index do |response, index|
      CacheODataJob.cache_response(response, logger: Delayed::Worker.logger)
      update_notes if (index % NOTES_INTERVAL).zero?
    end
  end

  def update_notes
    num_responses = remaining_responses.count
    notes = "#{I18n.t('operation.notes.remaining')}: #{num_responses}"
    Delayed::Worker.logger.info(notes)
    existing_operation&.update!(notes: notes)
  end

  def enqueue_operation
    Delayed::Worker.logger.info("Creating operation...")
    operation = Operation.new(
      creator: nil,
      mission: nil,
      job_class: CacheODataOperationJob,
      details: I18n.t("operation.details.cache_odata"),
      job_params: {}
    )
    operation.enqueue
  end

  # Self-enqueue a new batch if there are responses left to cache.
  def loop_or_finish
    if remaining_responses.exists?
      self.class.perform_later
    else
      complete_operation
    end
  end

  def complete_operation
    Delayed::Worker.logger.info("Done.")
    Operation.where(job_class: CacheODataOperationJob.name, job_completed_at: nil)
      .update(job_completed_at: Time.current, notes: "#{I18n.t('operation.notes.remaining')}: 0")
  end
end
