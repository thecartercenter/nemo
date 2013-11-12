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
end
