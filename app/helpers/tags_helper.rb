# DEPRECATED: Should move to a decorator.
module TagsHelper
  # options[:clickable] (bool) - make tags clickable to filter by clicked tag
  def render_tags(objects, options = {})
    return "" if objects.blank?
    title = options[:clickable] ? I18n.t("tag.click_to_filter") : nil
    classes = "tag"
    classes << " clickable" if options[:clickable]
    content_tag(:div, class: "tags") do
      spans = objects.map do |obj|
        content = options[:clickable] && options[:link_method] ? send(options[:link_method], obj) : obj.name
        content_tag(:span, content, class: classes, title: title)
      end
      safe_join(spans)
    end
  end
end
