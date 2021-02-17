# frozen_string_literal: true

module SmsGuideHelper
  # Returns an answer space for the given question type
  def answer_space_for_questioning(qing)
    # determine the number of spaces
    width =
      case qing.question.qtype.name
      when "integer", "counter" then 3
      when "select_one"
        if qing.sms_formatting_as_text? then 8
        elsif qing.sms_formatting_as_appendix? then 4
        else 1
        end
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
    loop do
      idx -= 1
      r = idx % 26
      idx /= 26
      letter = (r + 97).chr + letter
      break if idx <= 0
    end
    letter
  end

  # Returns an example answer based on the question type, to be used in the sms guide
  def sms_example_for_questioning(qing, locale:)
    content =
      case qing.qtype_name
      when "integer", "counter" then "3"
      when "decimal" then "12.5"
      when "select_one"
        if qing.sms_formatting_as_text?
          qing.first_leaf_option_node.name(locale, fallbacks: true)
        elsif qing.sms_formatting_as_appendix?
          qing.first_leaf_option_node.shortcode
        else
          "b"
        end
      when "select_multiple" then "a,c"
      when "datetime" then "20120228 1430"
      when "date" then "20121118"
      when "time" then "0930"
      end

    if content
      t("common.example_abbr", locale: @locale).html_safe <<
        " " << content_tag(:span, content, class: "sms-example")
    else
      ""
    end
  end

  # returns the type of pointer to show on the SMS guide
  def pointer_type(qing)
    case qing.qtype_name
    when "select_one"
      if qing.sms_formatting_as_text?
        "select_one_as_text"
      elsif qing.sms_formatting_as_appendix?
        "select_one_with_appendix"
      else
        qing.qtype_name
      end
    when "select_multiple"
      if qing.sms_formatting_as_appendix?
        "select_multiple_with_appendix"
      else
        qing.qtype_name
      end
    when "integer", "decimal", "counter"
      "number"
    when "text", "long_text"
      "text"
    else
      qing.qtype_name
    end
  end

  # returns the sms submit number or an indicator that it's not set up
  def submit_numbers
    numbers = if @incoming_sms_numbers.empty?
                "[#{t('sms_form.guide.unknown_number')}]"
              else
                @incoming_sms_numbers.join(", ")
              end
    content_tag("strong", numbers)
  end

  def sms_guide_hint(qing, locale:)
    hint = "".html_safe << (qing.question.hint(locale, fallbacks: true) || "")
    hint << "." unless hint =~ /\.\z/ || hint.empty?
    hint << " " << t(".pointers.#{pointer_type(qing)}", locale: locale)
    hint << " " << sms_example_for_questioning(qing, locale: locale)
  end

  def appendix_alert
    appendix_links = []

    appendix_links << link_to(t(".multiple_sms_numbers"), incoming_numbers_sms_path) if @number_appendix

    @form.option_sets_with_appendix.each do |option_set|
      appendix_links << link_to("#{OptionSet.model_name.human}: #{option_set.name}",
        export_option_set_path(option_set))
    end

    if appendix_links.empty?
      nil
    else
      alerts(notice: if appendix_links.size == 1
                       t(".appendix", count: 1).html_safe << " " << appendix_links.first
                     else
                       t(".appendix", count: 2).html_safe << content_tag(:ol) do
                         appendix_links.map { |l| content_tag(:li, l) }.reduce(:<<)
                       end
                     end)
    end
  end
end
