# frozen_string_literal: true

shared_context "odk submissions" do
  # TODO: Possibly combine with similar general_spec_helpers#prepare_odk_fixture.
  def prepare_odk_response_fixture(fixture_name, form, options = {})
    prepare_odk_fixture(name: fixture_name, type: :response, form: form, **options)
  end

  def prepare_and_upload_submission_file(template)
    tmp_path = Rails.root.join("tmp/submission.xml")
    File.open(tmp_path, "w") do |f|
      f.write(prepare_odk_media_upload_fixture(template, form))
    end
    Rack::Test::UploadedFile.new(tmp_path, "text/xml")
  end

  def post_submission(submission_file, image_name, image, incomplete: true)
    submission_params = {
      xml_submission_file: submission_file,
      image_name => image
    }
    submission_params["*isIncomplete*"] = "yes" if incomplete
    post(submission_path, params: submission_params, headers: auth_header)
  end

  private

  def prepare_odk_media_upload_fixture(filename, form)
    prepare_fixture("odk/responses/#{filename}",
      form: [form.id],
      formver: [form.number],
      itemcode: ODK::DecoratorFactory.decorate_collection(form.preordered_items).map(&:odk_code))
  end
end
