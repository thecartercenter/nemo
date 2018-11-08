module AnswersHelper
  # assuming excerpts are enclosed with {{{ ... }}}, safely converts to <em> tags and returns html_safe string
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

  def media_path(object, params = {})
    media_object_path(object, params.merge(type: object.kind.pluralize))
  end

  def thumb_path(object, params = {})
    object.thumb_path || media_path(object, params.merge(style: :thumb))
  end

  # Creates a media thumbnail link
  def media_link(object, show_delete: false)
    if object.nil?
      content_tag(:div, "[#{t("common.none")}]", class: "no-value")
    else
      content_tag(:div, class: 'media-thumbnail') do
        concat(link_to(image_tag(thumb_path(object)), media_path(object), target: "_blank"))

        concat(content_tag(:div, class: "links") do
          concat(link_to(content_tag(:i, "", class: 'fa fa-download'), media_path(object, dl: "1"), class: "download"))

          if show_delete
            concat(link_to(content_tag(:i, "", class: 'fa fa-trash-o'), "#", class: 'delete',
              data: { "confirm-msg" => t("response.remove_media_object_confirm.#{object.kind}") }))
          end
        end)
      end
    end
  end
end
