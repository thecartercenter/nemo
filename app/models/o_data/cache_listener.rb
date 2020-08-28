# frozen_string_literal: true

module OData
  # Marks the OData cached_json as dirty when things change.
  class CacheListener
    include Singleton

    def update_response_successful(response)
      # TODO: Eventually update the metadata ONLY.
      return unless attribs_changed?(response, %w[shortcode form_id user_id reviewed])
      response.update!(dirty_json: true)
    end

    def update_form_successful(form)
      return unless attribs_changed?(form, %w[name])
      Response.where(form_id: form.id).update_all(dirty_json: true)
    end

    def update_user_successful(user)
      return unless attribs_changed?(user, %w[name])
      Response.where(user_id: user.id).update_all(dirty_json: true)
    end

    private

    def attribs_changed?(object, attribs)
      (attribs & object.saved_changes.keys).any?
    end
  end
end

# Example JSON:
# {
#   "ResponseID": "ddf85bb0-2d3b-4643-b967-b13dd8635d3a",
#   "ResponseShortcode": "jz-gts-u0w5d",
#   "FormName": "My form",
#   "ResponseSubmitterName": "User 1",
#   "ResponseSubmitDate": "2020-01-01T23:41:10Z",
#   "ResponseReviewed": false,
#   "TextQ1": "foo",
#   "group1": {
#     "TextQ2": null,
#     "SelectOneQ3": "Cat"
#   }
# }
