# frozen_string_literal: true

# Base decorator for all decorators in app.
class ApplicationDecorator < Draper::Decorator
  delegate :t, :can?, :safe_str, to: :h

  def conditional_tag(name, condition, options = {}, &block)
    condition ? content_tag(name, options, &block) : yield
  end

  def nbsp
    "&nbsp;".html_safe # rubocop:disable Rails/OutputSafety
  end

  def show_action?
    h.controller.action_name == "show"
  end

  def edit_action?
    %w[edit update].include?(h.controller.action_name)
  end
end
