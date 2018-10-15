class BroadcastOperationJob < OperationJob
  def perform(operation, broadcast)
    broadcast.deliver
  rescue Sms::Errors::PartialError => e
    # this is considered a success but we'd still like to show there were some errors
    operation.update!(
      job_error_report: I18n.t("operation.errors.broadcast_partial", url: error_url(broadcast))
    )
  rescue Sms::Errors::FatalError => e
    # this is considered an full operation failure
    save_failure(I18n.t("operation.errors.broadcast_fatal", url: error_url(broadcast)))
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
