# DEPRECATED: Should move to a decorator.
module TagsHelper
  # options[:class] - additional class(es) to add to ul
  # options[:clickable] (bool) - make tags clickable to filter by clicked tag
  def render_tags(tags, options = {})
    if options[:clickable]
      options[:class] = options[:class].to_s + ' clickable'
      title = I18n.t 'tag.click_to_filter'
    else
      title = ''
    end
    if tags.present?
      content_tag(:ul, class: "tags #{options[:class]}") do
        tags.map do |tag|
          content_tag(:li, tag.name, class: "token-input-token-elmo", title: title)
        end.reduce(:<<)
      end
    else
      ''
    end
  end
end
