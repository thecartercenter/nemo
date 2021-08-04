# frozen_string_literal: true

require "rails_helper"

describe ODK::FormRenderJob do
  let!(:form) { create(:form, :live, name: "My Form") }

  it "stores rendered form in attachment" do
    described_class.perform_now(form)
    expect(form.reload.odk_xml.open(&:read)).to include("<h:title>My Form</h:title>")
  end
end
