module SearchesHelper
  def search_examples(search)
    examples = I18n.t("search.examples.#{controller_name}", :default => "")
    examples = examples.join("&nbsp;&nbsp;&nbsp;") if examples.is_a?(Array)
    
    unless examples.blank?
      content_tag("div", :id => "search_examples") do
        ("#{t("common.example", :count => 2)}:&nbsp;&nbsp;&nbsp;#{examples}").html_safe
      end
    end
  end
end