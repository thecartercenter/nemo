# frozen_string_literal: true

module ActionLinks
  # Builds a list of action links for a form.
  class FormLinkBuilder < LinkBuilder
    def initialize(form)
      actions = %i[show edit clone export]

      unless h.admin_mode?
        actions << [:go_live, {method: :patch}] unless form.live?
        actions << [:pause, {method: :patch}] if form.live?
        actions << [:return_to_draft, {method: :patch}] if form.not_draft?
        actions << [:print, {url: "#", data: {"form-id": form.id}}]

        if form.smsable?
          actions << :sms_guide
          actions << [:sms_console, h.new_sms_test_path] if can?(:create, Sms::Test)
        end
        if can?(:re_cache, form) || can?(:view_raw_odata, form)
          actions << link_divider
          actions << [:re_cache, {method: :patch}] if can?(:re_cache, form)
          actions << [:view_raw_odata, {url: api_url(form)}] if can?(:view_raw_odata, form)
        end
      end
      actions << :destroy
      super(form, actions)
    end

    private

    def api_url(form)
      return nil unless form.persisted? # Fixes a crash; this URL is meaningless for the 'new' route anyway.
      base_path = "#{h.request.base_url}#{h.current_root_path}#{OData::BASE_PATH}"
      responses_path = OData::FormDecorator.new(form).responses_url
      "#{base_path}/#{responses_path}"
    end
  end
end
