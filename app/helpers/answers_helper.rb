module AnswersHelper
  def format_answer(answer, context)
    return '' if answer.nil?

    case answer.questioning.question.qtype_name
    when "select_one"
      answer.option.name
    when "select_multiple"
      answer.choices.map{|c| c.option.name}.join(', ')
    when "datetime"
      I18n.l(answer.datetime_value)
    when "date"
      I18n.l(answer.date_value)
    when "time"
      I18n.l(answer.time_value, :format => :time_only)
    when "decimal"
      "%.2f" % answer.value.to_f
    when "long_text"
      context == :table_cell ? truncate(answer.value, :length => 32) : answer.value
    else
      answer.value
    end
  end

  # generates an excerpt given a string and an excerpter
  # if excerpter or string is nil, just returns the string
  def safe_excerpt(str, excerpter)
    return str if excerpter.nil? || str.nil?
    excerpt_to_html(excerpter.excerpt!(str))
  end

  # assuming excerpts are enclosed with {{{ ... }}}, safely converts to <em> tags and returns html_safe string
  def excerpt_to_html(str)
    h(str).gsub('{{{', '<em class="match">').gsub('}}}', '</em>').html_safe
  end
end