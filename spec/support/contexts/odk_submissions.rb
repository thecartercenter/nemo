# frozen_string_literal: true

shared_context "odk submissions" do
  def prepare_odk_response_fixture(fixture_name, form, options = {})
    prepare_odk_fixture(name: fixture_name, type: :response, form: form, **options)
  end
end
