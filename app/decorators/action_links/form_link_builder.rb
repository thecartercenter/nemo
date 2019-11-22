# frozen_string_literal: true

module ActionLinks
  # Builds a list of action links for a form.
  class FormLinkBuilder < LinkBuilder
    def initialize(form)
      actions = %i[show edit clone]
      unless h.admin_mode?
        actions << [:go_live, method: :patch] unless form.live?
        actions << [:pause, method: :patch] if form.live?
        actions << [:return_to_draft, method: :patch] if form.not_draft?
        if form.smsable?
          actions << :sms_guide
          actions << [:sms_console, h.new_sms_test_path] if can?(:create, Sms::Test)
        end
      end
      actions << :destroy
      super(form, actions)
    end
  end
end
