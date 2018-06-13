class Report::Formatter
  extend ActionView::Helpers::TextHelper

  def self.format(value, type, context)
    return nil if value.nil?
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
      sanitize(context == :header ? truncate(value, length: 96) : value)
    else
      value.is_a?(String) ? sanitize(value) : value
    end
  end

  # Checks if the value looks like a translation hash. If it does, pick the appropriate one.
  def self.translate(value)
    if value.is_a?(Hash)
      value[I18n.locale.to_s].presence || value[I18n.default_locale.to_s].presence || value.values.first
    else
      value
    end
  end

  def self.sanitize(value)
    ActionController::Base.helpers.sanitize(value)
  end
end
