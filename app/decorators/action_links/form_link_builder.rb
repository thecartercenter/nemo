# frozen_string_literal: true

module ActionLinks
  # Builds a list of action links for a form.
  class FormLinkBuilder < LinkBuilder
    def initialize(form)
      actions = %i[show edit clone]
      unless h.admin_mode?
        actions << [:go_live, {method: :patch}] unless form.live?
        actions << [:pause, {method: :patch}] if form.live?
        actions << [:return_to_draft, {method: :patch}] if form.not_draft?
        actions << [:print, {url: "#", data: {"form-id": form.id}}]
        if form.smsable?
          actions << :sms_guide
          actions << [:sms_console, h.new_sms_test_path] if can?(:create, Sms::Test)
        end
        actions << [:re_cache, {method: :patch}] if can?(:re_cache, form)
      end
      actions << :destroy
      super(form, actions)
    end
  end
end
