module AnswersHelper
  def format_answer(answer, context)
    return '' if answer.nil?

    case answer.qtype.name
    when "select_one"
      answer.option.try(:name)
    when "select_multiple"
      answer.choices && answer.choices.map{|c| c.option.name}.join(', ')
    when "datetime", "date"
      answer.casted_value.present? ? I18n.l(answer.casted_value) : ''
    when "time"
      answer.time_value.present? ? I18n.l(answer.time_value, :format => :time_only) : ''
    when "decimal"
      answer.value.present? ? "%.2f" % answer.value.to_f : ''
    when "long_text"
      if answer.value.present?
        value = sanitize(answer.value)
        context == :table_cell ? truncate(value, length: 32, escape: false) : value
      else
        ''
      end
    else
      answer.value
    end
  end

  # generates an excerpt given a string and an excerpter
  # if excerpter or string is nil, just returns the string
  def safe_excerpt(str, excerpter)
    return str if excerpter.nil? || str.nil?
    excerpt_to_html(excerpter.excerpt!(str))
  end

  # assuming excerpts are enclosed with {{{ ... }}}, safely converts to <em> tags and returns html_safe string
  # This is safe since we are escaping str before inserting the <em> tags, and also Sphinx should be
  # stripping html from the excerpts.
  def excerpt_to_html(str)
    html_escape(str).gsub('{{{', '<em class="match">').gsub('}}}', '</em>').html_safe
  end

  # checks for an excerpt for the given answer in the given response object and shows it if found
  # applies simple formatting
  def excerpt_if_exists(response, answer)
    html = if excerpt = response.excerpts_by_questioning_id[answer.questioning_id]
      excerpt_to_html(excerpt[:text])
    else
      answer.value
    end
    simple_format(html) #rely on simple_format to sanitize by default
  end

  # Creates a media thumbnail link
  def media_link(object, show_delete: false)
    if object.nil?
      content_tag(:div, "[#{t("common.none")}]", class: "no-value")
    else
      content_tag(:div, class: 'media-thumbnail') do
        concat(link_to(image_tag(object.thumb_path), object.token_url, target: "_blank"))

        concat(content_tag(:div, class: "links") do
          concat(link_to(content_tag(:i, "", class: 'fa fa-download'), object.download_url, class: 'download'))

          if show_delete
            concat(link_to(content_tag(:i, "", class: 'fa fa-trash-o'), "#", class: 'delete',
              data: { "confirm-msg" => t("response.remove_media_object_confirm.#{object.kind}") }))
          end
        end)
      end
    end
  end
end
