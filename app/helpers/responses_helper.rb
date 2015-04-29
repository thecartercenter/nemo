module ResponsesHelper
  def responses_index_fields
    # if in dashboard mode, don't put as many fields
    if params[:controller] == 'welcome'
      fields = %w(form_id user_id) + key_question_hashes(2) + %w(created_at reviewed)
    else
      fields = %w(id form_id user_id) + key_question_hashes(2) + %w(incomplete created_at age reviewed actions)
    end
  end

  # returns an array of hashes representing the key question column(s)
  def key_question_hashes(n)
    Question.accessible_by(current_ability).key(n).map{|q| {:title => q.code, :css_class => q.code.downcase, :question => q}}
  end

  def format_responses_field(resp, field)
    # handle special case where field is hash
    if field.is_a?(Hash)
      format_answer(resp.answer_for_question(field[:question]), :table_cell)
    else
      case field
      when "id" then link_to(resp.id, path_for_with_search(resp), :title => t("common.view"))
      when "form_id" then link_to(resp.form.name, resp.form)
      when "created_at" then resp.created_at ? l(resp.created_at) : ""
      when "age" then resp.created_at ? time_ago_in_words(resp.created_at) : ""
      when "incomplete" then tbool(resp.incomplete?)
      when "reviewed" then reviewed_status(resp)
      when "user_id" then can?(:read, resp.user) ? link_to(resp.user.name, resp.user) : resp.user.name
      when "actions"
        # we don't need to authorize these links b/c for responses, if you can see it, you can edit it.
        # the controller actions will still be auth'd
        by = resp.user ? " by #{resp.user.name}" : ""
        table_action_links(resp, :obj_description => resp.user ?
          "#{Response.model_name.human} #{t('common.by').downcase} #{resp.user.name}" :
          "#{t('common.this').downcase} #{Response.model_name.human}")
      else resp.send(field)
      end
    end
  end

  def responses_index_links(responses)
    links = []

    # only add the export link if there are responses and the user is auth'd to export
    if !responses.empty? && can?(:export, Response)
      links << link_to(t("response.export_to_csv"), responses_path(:format => :csv, :search => params[:search]))
    end

    # return the assembled list of links
    links
  end

  # shows response excerpts if available
  def responses_second_row(response)
    if response.excerpts
      # loop over each
      response.excerpts.map do |e|
        # force the string to be escaped before adding more tags
        html = excerpt_to_html(e[:text])

        # add the code
        "<p><b>[#{e[:code]}]:</b> #{html}</p>"
      end.join('').html_safe
    end
  end

  # builds a small inline form consisting of a dropdown for choosing a Form to which to submit a new response
  def new_response_mini_form(visible = true)
    form_tag(new_response_path, :method => :get, :id => "form_chooser", :style => visible ? "" : "display: none") do
      select_tag(:form_id, sel_opts_from_objs(@pubd_forms, :name_method => :full_name, :tags => true),
        :prompt => t("form.choose_form"), :onchange => "this.form.submit()")
    end
  end

  # converts the given responses to csv
  def responses_to_csv(responses)
    if responses.empty?
      ""
    else
      # We use \r\n because Excel seems to prefer it.
      CSV.generate(row_sep: "\r\n") do |csv|
        # add header row
        csv << responses.first.attributes.keys

        # add rest of rows
        responses.each do |r|
          attribs = r.attributes.dup

          # Format any paragraph style text.
          attribs['question_name'] = format_csv_para_text(attribs['question_name'])
          if attribs['question_type'] == 'long_text'
            attribs['answer_value'] = format_csv_para_text(attribs['answer_value'])
          end

          csv << attribs.values
        end
      end
    end
  end

  # takes a recent count (e.g. [5, "week"]) and translates it
  def translate_recent_responses(count)
    if count.nil?
      tmd("welcome.no_recent")
    else
      tmd("welcome.in_the_past_#{count[1]}", :count => number_with_delimiter(count[0]))
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
