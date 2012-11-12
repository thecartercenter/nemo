class Report::Formatter
  def self.format(value, type)
    case type
    when "date"
      # cast mysql date to nice string
      value.to_s.gsub(" 00:00:00", "")
    when "decimal"
      "%.2f" % value
    else
      value
    end
  end
end