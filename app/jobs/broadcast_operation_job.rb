# frozen_string_literal: true

# Delivers a broadcast in the context of a background operation
class BroadcastOperationJob < OperationJob
  def perform(operation, broadcast_id)
    broadcast = Broadcast.find(broadcast_id)
    broadcast.deliver
    broadcast.update!(sent_at: Time.current)
  rescue ActiveRecord::RecordNotFound
    save_failure(I18n.t("operation.errors.broadcast.not_found"))
  rescue Sms::Adapters::PartialSendError
    # this is considered a success but we'd still like to show there were some errors
    operation.update!(
      job_error_report: I18n.t("operation.errors.broadcast.partial_send", url: error_url(broadcast))
    )
    broadcast.update!(sent_at: Time.current)
  rescue Sms::Adapters::FatalSendError
    # this is considered an full operation failure
    save_failure(I18n.t("operation.errors.broadcast.fatal_send", url: error_url(broadcast)))
  end

  private

  def error_url(broadcast)
    broadcast_path(
      broadcast,
      mission_name: operation.mission.compact_name,
      locale: I18n.locale
    )
  end
end
