# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
class StubbedODataController < ApplicationController
  skip_authorization_check

  before_action :print_request
  before_action :set_headers

  def root
    render(json: %(
{
  "@odata.context":"#{request.url}/$metadata",
  "value": [
    { "name": "Responses: Foo", "kind": "EntitySet", "url": "Responses-123" }
  ]
}
    ).strip)
  end

  def metadata
    render(xml: %(
<?xml version="1.0" encoding="UTF-8"?>
<edmx:Edmx Version="4.0" xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx">
  <edmx:DataServices>
    <Schema Namespace="NEMO" xmlns="http://docs.oasis-open.org/odata/ns/edm">
      <EntityType Name="Responses: Foo" OpenType="true"></EntityType>
      <EntityContainer Name="NEMOService">
        <EntitySet Name="Responses: Foo" EntityType="NEMO.Responses: Foo"></EntitySet>
      </EntityContainer>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>
    ).strip)
  end

  def resource
    render(json: %(
{
    "@odata.context": "#{request.url}$metadata#Responses: Foo",
    "value": [
        {
            "FormName": "Foo",
            "ResponseReviewed": false
        }
    ]
}
    ).strip)
  end

  private

  def set_headers
    response.set_header("Odata-Version", "4.0")
  end

  def print_request
    Rails.logger.debug("GET #{request.url}")
    Rails.logger.debug(params.inspect)
  end
end
# rubocop:enable Metrics/MethodLength
