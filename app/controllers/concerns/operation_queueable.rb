# frozen_string_literal: true

# For controllers that need to enqueue operations.
module OperationQueueable
  extend ActiveSupport::Concern

  def prep_operation_queued_flash(type)
    flash[:html_safe] = true
    flash[:notice] = t("operation.queued_msg.#{type}") <<
      " " << t("operation.op_panel_more_info_link_html", url: operations_path)
  end
end
