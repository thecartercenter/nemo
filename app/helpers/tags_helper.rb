# frozen_string_literal: true

# DEPRECATED: Should move to a decorator.
module TagsHelper
  # options[:clickable] (bool) - make tags clickable to filter by clicked tag
  def render_tags(objects, options = {})
    return "" if objects.blank?
    title = options[:clickable] ? I18n.t("tag.click_to_filter") : nil
    classes = "badge badge-custom#{options[:clickable] ? ' clickable' : ''}"
    content_tag(:div, class: "tags") do
      spans = objects.map do |obj|
        if options[:clickable] && options[:link_method]
          send(options[:link_method], obj, class: classes, title: title)
        else
          content_tag(:span, obj.name, class: classes, title: title)
        end
      end
      safe_join(spans)
    end
  end
end
