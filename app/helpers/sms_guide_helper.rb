module SmsGuideHelper

  # Returns an answer space for the given question type
  def answer_space_for_questioning(qing)
    # determine the number of spaces
    width = case qing.question.qtype.name
    when "integer" then 3
    when "select_one" then qing.text_type_for_sms? ? 8 : 1
    when "decimal" then 3
    when "time", "select_multiple" then 4
    when "date" then 6
    when "datetime", "text", "long_text" then 8
    else 4
    end

    answer_space(width: width)
  end

  # Returns a blank space for an answer to be written in.
  def answer_space(width: 1, content: "")
    content_tag(:div, content, class: "answer-space width-#{width}")
  end

  # Returns a space glyph type thing for use in the sms guide.
  def spc_glyph
    image_tag("sms_guide/spc.png")
  end

  # Returns a period glyph type thing for use in the sms guide.
  def period_glyph
    content_tag("span", "●", class: "period-glyph")
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

  # Returns an example answer based on the question type, to be used in the sms guide
  def sms_example_for_questioning(qing)
    content = case qing.qtype_name
    when "integer" then "3"
    when "decimal" then "12.5"
    when "select_one" then qing.text_type_for_sms? ? qing.first_leaf_option.name : "b"
    when "select_multiple" then "a,c"
    when "datetime" then "20120228 1430"
    when "date" then "20121118"
    when "time" then "0930"
    else nil
    end

    if content
      t("common.example_abbr").html_safe << " " << content_tag(:span, content, class: "sms-example")
    else
      ""
    end
  end

  # returns the sms submit number or an indicator that it's not set up
  def submit_numbers
    numbers = if configatron.incoming_sms_numbers.empty?
      "[" + t("sms_form.guide.unknown_number") + "]"
    else
      configatron.incoming_sms_numbers.join(", ")
    end
    content_tag("strong", numbers)
  end

  def sms_guide_hint(qing)
    qtype_name = qing.text_type_for_sms? ? 'select_one_as_text' : qing.qtype_name
    hint = "".html_safe << (qing.question.hint || "")
    hint << "." unless hint =~ /\.\z/ || hint.empty?
    hint << " " << t(".pointers.#{qtype_name}")
    hint << " " << sms_example_for_questioning(qing)
  end
end
