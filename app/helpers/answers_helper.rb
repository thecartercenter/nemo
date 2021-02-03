# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module AnswersHelper
  def thumb_path(object)
    return object.static_thumb_path unless object.dynamic_thumb?

    # 100px container, doubled to 200 to support retina screens.
    url_for(object.item.variant(resize_to_limit: [200, 200]))
  end

  # Creates a media link with 3 main variants:
  # thumbnail, link to full size, button to download full size.
  def media_link(object, show_delete: false)
    return content_tag(:div, "[#{t('common.none')}]", class: "no-value") if object.nil?

    content_tag(:div, class: "media-thumbnail") do
      concat(
        link_to(image_tag(thumb_path(object)), url_for(object.item), target: "_blank", rel: "noopener")
      )

      concat(
        content_tag(:div, class: "links") do
          dl_path = rails_blob_path(object.item, disposition: "attachment")
          concat(
            link_to(content_tag(:i, "", class: "fa fa-download"), dl_path, class: "download")
          )

          if show_delete
            data = {"confirm-msg" => t("response.remove_media_object_confirm.#{object.kind}")}
            concat(
              link_to(content_tag(:i, "", class: "fa fa-trash-o"), "#", class: "delete", data: data)
            )
          end
        end
      )
    end
  end
end
