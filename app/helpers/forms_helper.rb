module FormsHelper
  def forms_index_links(forms)
    [link_to_if_auth("Create Form", new_form_path, "forms#create"),
      link_to_if_auth("SMS Test Console", new_sms_test_path, "sms_tests#create")]
  end
  
  def forms_index_fields
    %w[type version name questions published? smsable last_modified downloads responses actions]
  end
    
  def format_forms_field(form, field)
    case field
    when "type" then form.type.name
    when "version" then form.current_version ? form.current_version.sequence : ""
    when "questions" then form.questionings_count
    when "last_modified" then form.updated_at.to_s(:std_datetime)
    when "responses"
      form.responses_count == 0 ? 0 :
        link_to(form.responses_count, responses_path(:search => "form:\"#{form.name}\""))
    when "downloads" then form.downloads || 0
    when "published?" then form.published? ? "Yes" : "No"
    when "smsable" then form.smsable? ? "Yes" : "No"
    when "actions"
      exclude = form.published? ? [:edit, :destroy] : []
      action_links = action_links(form, :destroy_warning => "Are you sure you want to delete form '#{form.name}'?", 
        :exclude => exclude)
        
      pl_img = action_icon(form.published? ? "unpublish" : "publish")
      publish_link = link_to_if_auth(pl_img, publish_form_path(form), "forms#publish", form, 
        :title => "#{form.published? ? 'Unp' : 'P'}ublish")
      
      clone_link = link_to_if_auth(action_icon("clone"), clone_form_path(form), "forms#clone", form, 
        :title => "Clone", :confirm => "Are you sure you want to make a copy of the form '#{form.name}'?")

      print_link = link_to_if_auth(action_icon("print"), "#", "forms#show", form, :title => "Print",
        :onclick => "Form.print(#{form.id}); return false;")
        
      sms_link = if form.smsable? && form.published?
        link_to_if_auth(action_icon("sms"), form_path(form, :sms_guide => 1), "forms#show", form, :title => "Sms Guide")
      else
        ""
      end
      
      (action_links + publish_link + clone_link + print_link + sms_link + loading_indicator(:id => form.id, :floating => true)).html_safe
    else form.send(field)
    end
  end
  
  # given a Questioning object, builds an odk <input> tag
  # calls the provided block to get the tag content
  def odk_input_tag(qing, &block)
    opts = {}
    opts[:ref] = "/data/#{qing.question.odk_code}"
    opts[:appearance] = "tall" if qing.question.type.name == "long_text"
    content_tag(qing.question.type.odk_tag, opts, &block)
  end
  
  # returns a set of divs making up an answer space for the given text for use in the sms guide
  def answer_space(text, options = {})
    # default to showing the spc glyph
    options[:show_spc_glyph] = true if options[:show_spc_glyph].nil?
    
    text.split("").collect do |char|
      content_tag("span", :class => "answer_space") do 
        case char
        when " " then options[:show_spc_glyph] ? spc_glyph : " "
        when "." then "&bull;".html_safe
        else char
        end
      end
    end.join.html_safe
  end
  
  # returns a SPC glyph type thing for use in the sms guide
  def spc_glyph
    content_tag("span", "SPC", :class => "spc_glyph")
  end
  
  # converts a number into a letter e.g. 1 = a, 2 = b, 3 = c, ..., 26 = z, 27 = aa, ...
  def index_to_letter(idx)
    letter = ""
    while true
      idx -= 1
      r = idx % 26
      idx /= 26
      letter = (r + 97).chr + letter
      break if idx <= 0
    end
    letter
  end
  
  # returns an example answer based on the question type, to be used in the sms guide
  def sms_example_for_question(qing)
    content = case qing.question.type.name
    when "integer" then "3"
    when "decimal" then "12.5"
    when "select_one" then "b"
    when "select_multiple" then "ac"
    when "datetime" then "20120228 1430"
    when "date" then "20121118"
    when "time" then "0930"
    else nil
    end
    
    (content ? t("common.example_abbr") + " " + content_tag(:span, content, :class => "sms_example") : "").html_safe
  end
  
  # returns a set of answer spaces for the given question type
  def answer_space_for_question(qing)
    # determine the number of spaces
    size = case qing.question.type.name
    when "integer", "select_one" then 1
    when "decimal" then 2
    when "time", "select_multiple" then 4
    when "date" then 6
    when "datetime", "tiny_text" then 8
    else 4
    end
    
    answer_space(" " * size, :show_spc_glyph => false)
  end
  
  # returns the sms submit number or an indicator that it's not set up
  def submit_number
    content_tag("strong", configatron.incoming_sms_number.blank? ? "[" + t("sms_forms.guide.unknown_number") + "]" : configatron.incoming_sms_number)
  end
end
