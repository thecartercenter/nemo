class ApplicationDecorator < Draper::Decorator
  def conditional_tag(name, condition, options = {}, &block)
    condition ? content_tag(name, options, &block) : yield
  end

  def safe_str
    "".html_safe
  end
end
