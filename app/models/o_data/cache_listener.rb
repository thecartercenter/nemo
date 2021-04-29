# frozen_string_literal: true

module OData
  # Marks the OData cached_json as dirty when things change.
  class CacheListener
    include Singleton

    def update_response_successful(response)
      # TODO: Eventually update the metadata ONLY.
      return unless attribs_changed?(response, %w[shortcode form_id user_id reviewed])
      Rails.logger.debug("OData dirty_json cause: updated response #{response.id}")
      response.update!(dirty_json: true)
    end

    def update_answer_successful(answer)
      return unless attribs_changed?(answer, %w[value date_value time_value datetime_value
                                                option_node_id accuracy altitude latitude longitude])
      Rails.logger.debug("OData dirty_json cause: updated answer #{answer.id}")
      answer.response.update!(dirty_json: true)
    end

    def update_form_successful(form)
      return unless attribs_changed?(form, %w[name])
      Rails.logger.debug("OData dirty_json cause: updated form #{form.id}")
      Response.where(form_id: form.id).update_all(dirty_json: true)
    end

    def update_user_successful(user)
      return unless attribs_changed?(user, %w[name])
      Rails.logger.debug("OData dirty_json cause: updated user #{user.id}")
      Response.where(user_id: user.id).update_all(dirty_json: true)
    end

    def update_question_successful(question)
      return unless attribs_changed?(question, %w[code])
      form_ids = question.forms.pluck(:id)
      Rails.logger.debug("OData dirty_json cause: updated question #{question.id}")
      Response.where(form_id: form_ids).update_all(dirty_json: true)
    end

    def update_questioning_successful(questioning)
      # Note: Simple rank changes are a "false positive"; could be
      # more performant if we listen specifically for *parent* changes
      # instead (though Wisper may not easily handle this attrib).
      return unless attribs_changed?(questioning, %w[rank])
      Rails.logger.debug("OData dirty_json cause: updated questioning #{questioning.id}")
      Response.where(form_id: questioning.form_id).update_all(dirty_json: true)
    end

    def update_qing_group_successful(qing_group)
      return unless attribs_changed?(qing_group, %w[rank repeatable group_name_translations])
      Rails.logger.debug("OData dirty_json cause: updated qing_group #{qing_group.id}")
      Response.where(form_id: qing_group.form.id).update_all(dirty_json: true)
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
