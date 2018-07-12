shared_context "odk submissions" do
  # Builds a form (unless xml provided) and sends a submission to the given path.
  def do_submission(path, xml = nil)
    if xml.nil?
      form = create(:form, question_types: %w(integer integer))
      form.publish!
      xml = build_odk_submission(form, data: {form.questionings[0] => "5", form.questionings[1] => "10"})
    end

    # write xml to file
    require "fileutils"
    fixture_file = Rails.root.join(Rails.root, "tmp", "odk_xml_file.xml")
    File.open(fixture_file.to_s, "w") { |f| f.write(xml) }

    # Upload and do request.
    uploaded = fixture_file_upload(fixture_file, "text/xml")
    post(path, params: {xml_submission_file: uploaded, format: "xml"},
      headers: {"HTTP_AUTHORIZATION" => encode_credentials(user.login, test_password)})
    assigns(:response)
  end

  # Build a sample xml submission for the given form.
  # Takes answer value (should be a string) from given data hash (with questionings as keys) if present,
  # generates random int otherwise.
  def build_odk_submission(form, data: {}, override_form_id: false, repeat: false, no_data: false)
    # allow form id to be overridden for testing bad submissions
    form_id = override_form_id || form.id

    raise "form should have version" if form.current_version.nil?

    "".tap do |xml|
      xml << "<?xml version='1.0' ?><data id=\"#{form_id}\" version=\"#{form.current_version.code}\">"

      if no_data
        xml << "<#{Odk::FormDecorator::IR_QUESTION}>yes</#{Odk::FormDecorator::IR_QUESTION}>" if form.allow_incomplete?
      else
        i = 1
        descendants = form.arrange_descendants

        descendants.each do |item, subitems|
          decorated_item = Odk::DecoratorFactory.decorate(item)
          if item.is_a? QingGroup
            # Iterate over repeat instances (if any)
            Array.wrap(data[item] || {}).each do |instance|
              xml << "<grp#{item.id}><header/>"
              subitems.each do |subitem, _|
                if instance[subitem]
                  decorated_subitem = Odk::DecoratorFactory.decorate(subitem)
                  xml << "<#{decorated_subitem.odk_code}>"
                  xml << instance[subitem]
                  xml << "</#{decorated_subitem.odk_code}>"
                end
              end
              xml << "</grp#{item.id}>"
            end
          elsif item.multilevel?
            item.level_count.times do |level|
              xml << "<#{decorated_item.odk_code}_#{level + 1}>"
              xml << (data[item].try(:[], level) || rand(100).to_s)
              xml << "</#{decorated_item.odk_code}_#{level + 1}>"
            end
          else
            xml << "<#{decorated_item.odk_code}>"
            xml << (data[item] || rand(100).to_s)
            xml << "</#{decorated_item.odk_code}>"
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
