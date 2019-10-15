# frozen_string_literal: true

module ActionLinks
  # Builds a list of action links for a form.
  class FormLinkBuilder < LinkBuilder
    def initialize(form)
      actions = %i[show edit clone]
      actions << [:go_live, method: :put] unless form.live?
      actions << [:pause, method: :put] if form.live?
      if form.smsable? && !h.admin_mode?
        actions << :sms_guide
        actions << [:sms_console, h.new_sms_test_path] if can?(:create, Sms::Test)
      end
      actions << :destroy
      super(form, actions)
    end
  end
end
