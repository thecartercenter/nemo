class Report::Formatter
  extend ActionView::Helpers::TextHelper
  def self.format(value, type, context)
    value = translate(value)
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
  
  # checks if the value looks like a translation hash. if it does, pick the appropriate one
  def self.translate(value)
    # if it looks like a translation hash
    if value.is_a?(String) && value[0] == "{" && value =~ /\{"[a-z]{2}"/
      # parse it
      dict = JSON.parse(value)
      
      # return the appropriate value (try the current locale, then the default value, then give up)
      translated = dict[I18n.locale.to_s]
      translated = dict[I18n.default_locale.to_s] if translated.blank?
      translated = value if translated.blank?
      translated
    else
      value
    end
  end
end