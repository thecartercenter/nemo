module ODKSubmissionSupport
  ODK_XML_FILE = "odk_xml_file.xml"

  # Builds a form (unless xml provided) and sends a submission to the given path.
  def do_submission(path, xml = nil)
    if xml.nil?
      form = create(:form, question_types: %w(integer integer))
      form.publish!
      xml = build_odk_submission(form)
    end

    # write xml to file
    require "fileutils"
    fixture_file = Rails.root.join(Rails.root, "tmp", ODK_XML_FILE)
    File.open(fixture_file.to_s, "w") { |f| f.write(xml) }

    # Upload and do request.
    uploaded = fixture_file_upload(fixture_file, "text/xml")
    post(path, {xml_submission_file: uploaded, format: "xml"},
      "HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password))
    assigns(:response)
  end

  # Build a sample xml submission for the given form (assumes all questions are integer questions)
  # Assigns answers in the sequence 5, 10, 15, ...
  def build_odk_submission(form, options = {})
    # allow form id to be overridden for testing bad submissions
    form_id = options[:override_form_id] || form.id

    raise "form should have version" if form.current_version.nil?

    "".tap do |xml|
      xml << "<?xml version='1.0' ?><data id=\"#{form_id}\" version=\"#{form.current_version.code}\">"

      if options[:no_answers]
        xml << "<#{OdkHelper::IR_QUESTION}>yes</#{OdkHelper::IR_QUESTION}>" if form.allow_incomplete?
      else
        i = 1
        descendants = form.arrange_descendants

        descendants.each do |qing, subtree|
          if qing.is_a? QingGroup
            loop do
              xml << "<grp-#{qing.id}>"

              subtree.each do |qing, subtree|
                xml << "<#{qing.question.odk_code}>#{i*5}</#{qing.question.odk_code}>"
                i += 1
              end

              xml << "</grp-#{qing.id}>"
              break unless options[:repeat] && i <= descendants.flatten.size
            end
          else
            xml << "<#{qing.question.odk_code}>#{i*5}</#{qing.question.odk_code}>"
            i += 1
          end
        end
      end

      xml << "</data>"
    end
  end

  def submission_path(mission = nil)
    mission ||= get_mission
    "/m/#{mission.compact_name}/submission"
  end

  def allow_forgery_protection(allow)
    ActionController::Base.allow_forgery_protection = allow
  end
end
