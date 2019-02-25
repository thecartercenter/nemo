# frozen_string_literal: true

module ResponsesHelper
  def responses_index_fields
    if params[:controller] == "welcome" # Dashboard mode
      %w[form_id user_id] + key_question_hashes(2) + %w[created_at reviewed]
    else
      %w[shortcode form_id user_id] + key_question_hashes(2) +
        %w[incomplete created_at age reviewed reviewer_id]
    end
  end

  # returns an array of hashes representing the key question column(s)
  def key_question_hashes(count)
    Question.accessible_by(current_ability).key(count).map do |q|
      {title: q.code, css_class: q.code.downcase, question: q}
    end
  end

  def format_responses_field(resp, field)
    # handle special case where field is hash
    if field.is_a?(Hash)
      if (answer = resp.answer_for(field[:question]))
        Results::ResponseNodeDecorator.decorate(answer).shortened
      end
    else
      case field
      when "shortcode" then link_to(resp.shortcode, path_for_with_search(resp), title: t("common.view"))
      when "form_id" then resp.form.name
      when "created_at" then resp.created_at ? l(resp.created_at) : ""
      when "age" then resp.created_at ? time_ago_in_words(resp.created_at) : ""
      when "incomplete" then tbool(resp.incomplete?)
      when "reviewed" then reviewed_status(resp)
      when "user_id" then resp.user.name
      when "reviewer_id"
        return if resp.reviewer.blank?
        can?(:read, resp.reviewer) ? link_to(resp.reviewer.name, resp.reviewer) : resp.reviewer.name
      else resp.send(field)
      end
    end
  end

  def responses_index_links(responses)
    links = []

    # only add the export link if there are responses and the user is auth'd to export
    if !responses.empty? && can?(:export, Response)
      links << link_to(t("response.export_to_csv"), responses_path(format: :csv, search: params[:search]))
    end

    links << batch_op_link(
      name: t("response.bulk_destroy"),
      path: bulk_destroy_responses_path(search: params[:search]),
      confirm: "response.bulk_destroy_confirm"
    )

    # return the assembled list of links
    links
  end

  # shows response excerpts if available
  def responses_second_row(response)
    response.excerpts&.map do |e|
      html = excerpt_to_html(e[:text])
      content_tag(:p, content_tag(:b, "[#{e[:code]}]:") << " " << html)
    end&.reduce(:<<)
  end

  # takes a recent count (e.g. [5, "week"]) and translates it
  def translate_recent_responses(count)
    if count.nil?
      tmd("welcome.no_recent")
    else
      tmd("welcome.in_the_past_#{count[1]}", count: number_with_delimiter(count[0]))
    end
  end

  def reviewed_status(resp)
    status = tbool(resp.reviewed?)
    if !resp.checked_out_at.nil? && (resp.checked_out_at > Response::LOCK_OUT_TIME.ago)
      status = I18n.t("common.pending")
    end
    status
  end
end
