# frozen_string_literal: true

# Delivers a broadcast in the context of a background operation
class BroadcastOperationJob < OperationJob
  def perform(operation, broadcast_id:)
    broadcast = Broadcast.find(broadcast_id)
    broadcast.deliver
    broadcast.update!(sent_at: Time.current)
  rescue ActiveRecord::RecordNotFound
    save_failure(I18n.t("operation.errors.broadcast.not_found"))
  rescue Sms::Adapters::PartialSendError
    # This is considered a success but we'd still like to show there were some errors
    report = I18n.t("operation.errors.broadcast.partial_send", url: error_url(broadcast))
    operation.update!(job_error_report: report)
    broadcast.update!(sent_at: Time.current)
  rescue Sms::Error
    # It is considered a full operation failure when we get the explicit FatalSendError (meaning
    # sending failed N times in a row) or a plain Error, which could have come up in various points
    # in the process. In the either case, the Broadcast will have more information about the failure.
    save_failure(I18n.t("operation.errors.broadcast.fatal_send", url: error_url(broadcast)))

    # We still set the timestamp here b/c otherwise the broadcast will show as pending.
    broadcast.update!(sent_at: Time.current)
  end

  private

  def error_url(broadcast)
    broadcast_path(broadcast, mission_name: mission.compact_name, locale: I18n.locale)
  end
end
