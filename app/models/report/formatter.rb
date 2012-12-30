class Report::Formatter
  extend ActionView::Helpers::TextHelper
  def self.format(value, type, context)
    case type
    when "date"
      # cast mysql date to nice string
      value.to_s.gsub(" 00:00:00", "")
    when "decimal"
      "%.2f" % value
    when "long_text"
      context == :header ? truncate(value, :length => 96) : value
    else
      value
    end
  end
end