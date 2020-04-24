# frozen_string_literal: true

module OData
  class SimpleEntities
    attr_reader :values

    def initialize
      # TODO: All published forms in the missions, regardless of if they have response
      @values = Response.distinct.pluck(:form_id).map do |id|
        name = Form.find(id).name
        SimpleEntity.new("Responses: #{name}")
      end
    end
  end
end
