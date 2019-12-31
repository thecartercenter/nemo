# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module AnswersHelper
  def media_path(object, params = {})
    media_object_path(object, params.merge(type: object.kind.pluralize))
  end

  def thumb_path(object, params = {})
    if object.dynamic_thumb?
      media_path(object, params.merge(style: :thumb))
    else
      object.static_thumb_path
    end
  end

  # Creates a media thumbnail link
  def media_link(object, show_delete: false)
    if object.nil?
      content_tag(:div, "[#{t('common.none')}]", class: "no-value")
    else
      content_tag(:div, class: "media-thumbnail") do
        concat(link_to(image_tag(thumb_path(object)), media_path(object), target: "_blank"))

        concat(content_tag(:div, class: "links") do
          concat(link_to(content_tag(:i, "", class: "fa fa-download"),
            media_path(object, dl: "1"), class: "download"))

          if show_delete
            concat(link_to(content_tag(:i, "", class: "fa fa-trash-o"),
              "#",
              class: "delete",
              data: {"confirm-msg" => t("response.remove_media_object_confirm.#{object.kind}")}))
          end
        end)
      end
    end
  end
end
