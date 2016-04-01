module SmsGuideHelper

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
    end.reduce(:<<)
  end

  # Returns a space glyph type thing for use in the sms guide.
  def spc_glyph
    image_tag("spc.png")
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
  def sms_example_for_question(qing)
    content = case qing.question.qtype.name
    when "integer" then "3"
    when "decimal" then "12.5"
    when "select_one" then qing.text_type_for_sms? ? qing.first_leaf_option.name : "b"
    when "select_multiple" then "ac"
    when "datetime" then "20120228 1430"
    when "date" then "20121118"
    when "time" then "0930"
    else nil
    end

    if content
      t("common.example_abbr").html_safe << " " << content_tag(:span, content, class: "sms_example")
    else
      ""
    end
  end

  # returns a set of answer spaces for the given question type
  def answer_space_for_question(qing)
    # determine the number of spaces
    size = case qing.question.qtype.name
    when "integer" then 1
    when "select_one" then qing.text_type_for_sms? ? 8 : 1
    when "decimal" then 2
    when "time", "select_multiple" then 4
    when "date" then 6
    when "datetime", "text", "long_text" then 8
    else 4
    end

    answer_space(" " * size, :show_spc_glyph => false)
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
end
