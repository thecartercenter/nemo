class Report::Formatter
  extend ActionView::Helpers::TextHelper
  def self.format(value, type, context)
    value = translate(value)
    case type
    when "datetime"
      I18n.l(value.is_a?(Time) ? value : Time.parse(value.to_s))
    when "date"
      I18n.l(value.is_a?(Date) ? value : Date.parse(value.to_s))
    when "time"
      I18n.l(value.is_a?(Time) ? value : Time.parse(value.to_s), :format => :time_only)
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
