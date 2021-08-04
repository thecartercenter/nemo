# frozen_string_literal: true

module ODK
  # Renders form to a file.
  class FormRenderJob < ApplicationJob
    def perform(form)
      form.odk_xml.attach(
        io: StringIO.new(FormRenderer.new(form).xml),
        filename: "#{form.id}.xml",
        content_type: "application/xml"
      )
    end
  end
end
