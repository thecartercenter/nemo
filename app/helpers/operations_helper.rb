# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module OperationsHelper
  def operations_index_fields
    [].tap do |fields|
      fields << "mission" if admin_mode?
      fields.concat(%w[details created_at])
      fields << "creator" if can?(:manage, Operation)
      fields.concat(%w[status result])
    end
  end

  def operations_index_links(_operations)
    [link_to(translate_action(Operation, :clear), clear_operations_path,
      method: :post, data: {confirm: t("operation.clear_confirm")})]
  end

  def format_operations_field(operation, field)
    case field
    when "mission"
      if (mission = operation.mission)
        link_to(mission.name, operations_path(mode: "m", mission_name: mission.compact_name))
      else
        t("admin_mode.admin_mode")
      end
    when "details"
      link_to(operation.details, operation.default_path)
    when "creator"
      if operation.creator
        link_to(operation.creator.name, user_path(operation.creator))
      else
        t("common.system")
      end
    when "created_at"
      t("layout.time_ago", time: time_ago_in_words(operation.created_at))
    when "status"
      link_to(t("operation.status.#{operation.status}"), operation.default_path)
    when "result"
      case operation.status
      when :failed
        link_to(t("operation.see_error_report"), operation.default_path)
      when :completed
        if operation.attachment.attached?
          link_to(t("operation.result_link_text.#{operation.kind}"), rails_blob_path(operation.attachment, disposition: "attachment"))
        end
      end
    else
      operation.send(field)
    end
  end

  def operations_status
    return if basic_mode? # There is no ops panel in basic mode.

    status = OperationStatus.new(Operation.accessible_by(current_ability).where(creator: current_user))

    if status.total?
      label =
        if status.in_progress?
          if status.completed?
            t("operation.summary.some_completed", completed: status.completed, total: status.total)
          else
            t("operation.summary.all_in_progress", count: status.in_progress)
          end
        else
          t("operation.summary.all_completed", count: status.completed)
        end

      label = t("operation.summary.with_errors", message: label, count: status.failed) if status.failed?

      link_to(icon_tag(:operation) + label, operations_path)
    else
      link_to(icon_tag(:operation) + t("operation.operations_panel"), operations_path)
    end
  end
end
