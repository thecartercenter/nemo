module TagsHelper
  # options[:class] - additional class(es) to add to ul
  def render_tags(tags, options = {})
    if tags.present?
      html = %{<ul class="tags #{options[:class]}">}
      tags.each do |tag|
        html << '<li class="token-input-token-elmo">'
        html << '<i class="fa fa-fw fa-certificate"></i> ' if tag.is_standard?
        html << tag.name
        html << '</li>'
      end
      html << '</ul>'
      raw html
    end
  end
end
