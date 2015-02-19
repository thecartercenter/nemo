module FormsHelper
  def forms_index_links(forms)
    links = []

    # add links based on authorization
    links << create_link(Form) if can?(:create, Form)
    links << link_to(t("page_titles.sms_tests.all"), new_sms_test_path) if can?(:create, Sms::Test)

    add_import_standard_link_if_appropriate(links)

    # return links
    links
  end

  def forms_index_fields
    if admin_mode?
      %w(std_icon name questions copy_count copy_responses_count updated_at actions)
    else
      %w(std_icon version name questions published downloads responses smsable allow_incomplete updated_at actions)
    end
  end

  def format_forms_field(form, field)
    case field
    when "std_icon" then std_icon(form)
    when "version" then form.version
    when "name" then link_to(form.name, form_path(form), :title => t("common.view"))
    when "questions" then form.questionings_count
    when "updated_at" then l(form.updated_at)
    when "responses"
      form.responses_count == 0 ? 0 :
        link_to(form.responses_count, responses_path(:search => "form:\"#{form.name}\""))
    when "downloads" then form.downloads || 0
    when "published" then tbool(form.published?)
    when "smsable" then tbool(form.smsable?)
    when "copy_count" then form.copy_count
    when "allow_incomplete" then tbool(form.allow_incomplete?)
    when "actions"
      # get standard action links
      links = table_action_links(form)

      # get the appropriate publish icon and add link, if auth'd
      if can?(:publish, form)
        verb = form.published? ? "unpublish" : "publish"
        links += action_link(verb, publish_form_path(form), :title => t("form.#{verb}"), :'data-method' => 'put')
      end

      # add a clone link if auth'd
      if can?(:clone, form)
        links += action_link("clone", clone_form_path(form), :'data-method' => 'put',
          :title => t("common.clone"), :confirm => t("form.clone_confirm", :form_name => form.name))
      end

      # add a print link if auth'd
      if can?(:print, form)
        links += action_link("print", "#", title: t("common.print"), class: 'print-link', :'data-form-id' => form.id)
      end

      # add an sms template link if appropriate
      if form.smsable? && form.published? && !admin_mode?
        links += action_link("sms", form_path(form, :sms_guide => 1), :title => "Sms Guide")
      end

      # add a loading indicator
      links += loading_indicator(:id => form.id, :floating => true)

      # return the links
      links.html_safe

    else form.send(field)
    end
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
    content = case qing.question.qtype.name
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
    size = case qing.question.qtype.name
    when "integer", "select_one" then 1
    when "decimal" then 2
    when "time", "select_multiple" then 4
    when "date" then 6
    when "datetime", "text", "long_text" then 8
    else 4
    end

    answer_space(" " * size, :show_spc_glyph => false)
  end

  # returns the sms submit number or an indicator that it's not set up
  def submit_number
    content_tag("strong", configatron.incoming_sms_number.blank? ? "[" + t("sms_form.guide.unknown_number") + "]" : configatron.incoming_sms_number)
  end

  def allow_incomplete?
    @form.allow_incomplete? && @style != 'commcare'
  end
end
