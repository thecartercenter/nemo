module SearchesHelper
  def search_examples(search)
    content_tag("div", :id => "search_examples") do 
      ("#{t("common.example", :count => 2)}:&nbsp;&nbsp;&nbsp;" + search.examples.join("&nbsp;&nbsp;&nbsp;")).html_safe
    end
  end
end