# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module ResponsesHelper
  def responses_index_fields
    if params[:controller] == "welcome" # Dashboard mode
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

  def responses_index_links(responses)
    links = []

    if !responses.empty? && can?(:export, Response)
      links << link_to(t("response.export_to_csv"), "#", id: "export-link")
    end

    links << batch_op_link(
      name: t("response.bulk_destroy"),
      path: bulk_destroy_responses_path(search: params[:search]),
      confirm: "response.bulk_destroy_confirm"
    )

    # return the assembled list of links
    links
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
