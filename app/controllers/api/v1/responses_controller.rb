# frozen_string_literal: true

require "will_paginate/array"
class API::V1::ResponsesController < API::V1::BaseController
  def index
    find_form
    unless performed?
      responses = @form.responses
      responses = add_date_filter(responses)
      paginate(json: API::V1::ResponseSerializer.render_as_json(responses))
    end
  end
end
