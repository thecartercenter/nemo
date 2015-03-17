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
      html = %{<ul class="tags #{options[:class]}">}
      tags.each do |tag|
        html << %{<li class="token-input-token-elmo" title="#{title}">}
        html << tag.name
        html << '</li>'
      end
      raw html << '</ul>'
    else
      ''
    end
  end
end
