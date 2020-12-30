# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module ResponsesHelper
  def responses_index_links(responses)
    links = []
    links << batch_op_link(
      name: t("action_links.destroy"),
      path: bulk_destroy_responses_path(search: params[:search]),
      confirm: "response.bulk_destroy_confirm"
    )
    links << link_divider
    links << export_dropdown(responses) if can?(:export, Response)
    links
  end

  def responses_index_fields
    if params[:controller] == "dashboard" # Dashboard mode
      %w[form_id user_id] + key_question_hashes(2) + %w[created_at reviewed]
    else
      %w[shortcode form_id user_id] + key_question_hashes(2) +
        %w[incomplete created_at age reviewed actions]
    end
  end

  # returns an array of hashes representing the key question column(s)
  def key_question_hashes(count)
    Question.accessible_by(current_ability).key(count).map { |q| {title: q.code, question: q} }
  end

  def format_responses_field(resp, field)
    # handle special case where field is hash
    if field.is_a?(Hash)
      if (answer = resp.answer_for(field[:question]))
        Results::ResponseNodeDecorator.decorate(answer).shortened
      end
    else
      case field
      when "shortcode" then link_to(resp.shortcode, resp.default_path, title: t("common.view"))
      when "form_id" then resp.form.name
      when "created_at" then resp.created_at ? l(resp.created_at) : ""
      when "age" then resp.created_at ? time_ago_in_words(resp.created_at) : ""
      when "incomplete" then tbool(resp.incomplete?)
      when "user_id" then resp.user.name
      when "reviewed" then resp.reviewed_status
      when "actions" then can?(:update, resp) ? [action_link(:edit, edit_response_path(resp))] : []
      else resp.send(field)
      end
    end
  end

  def export_dropdown(responses)
    [export_dropdown_parent, export_dropdown_children(responses)].reduce(:<<)
  end

  def export_dropdown_parent
    link_to(t("action_links.export"), "#", id: "export-dropdown",
                                           class: "dropdown-toggle",
                                           role: "button",
                                           "data-toggle": "dropdown",
                                           "aria-haspopup": "true")
  end

  def export_dropdown_children(responses)
    content_tag(:div, class: "dropdown-menu",
                      "aria-labelledby": "export-dropdown") do
      [
        unless responses.empty?
          link_to(t("response.export.to_csv"), "#", id: "export-csv-link",
                                                    class: "dropdown-item")
        end,
        link_to(t("response.export.to_odata"), "#", id: "export-odata-link",
                                                    class: "dropdown-item")
      ].compact.reduce(:<<)
    end
  end

  # takes a recent count (e.g. [5, "week"]) and translates it
  def translate_recent_responses(count)
    if count.nil?
      tmd("welcome.no_recent")
    else
      tmd("welcome.in_the_past_#{count[1]}", count: number_with_delimiter(count[0]))
    end
  end
end
