# frozen_string_literal: true

# Base decorator for all decorators in app.
class ApplicationDecorator < Draper::Decorator
  delegate :t, to: :h

  def conditional_tag(name, condition, options = {}, &block)
    condition ? content_tag(name, options, &block) : yield
  end

  # We use this string to concatenate other strings onto to build larger safe strings
  # and avoid having to call html_safe all over the place.
  def safe_str
    "".html_safe # rubocop:disable Rails/OutputSafety # It's an empty string!
  end

  def nbsp
    "&nbsp;".html_safe # rubocop:disable Rails/OutputSafety
  end
end
