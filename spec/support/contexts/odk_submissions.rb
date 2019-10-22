# frozen_string_literal: true

#######################################################################################################
# This context is DEPRECATED. Use newer methods of building XML fixtures instead. See ODK parser specs.
#######################################################################################################
shared_context "odk submissions" do
  # Builds a form (unless xml provided) and sends a submission to the given path.
  def do_submission(path, xml = nil)
    if xml.nil?
      form = create(:form, question_types: %w[integer integer])
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
        descendants = arrange_descendants(form)

        descendants.each do |item, subitems|
          decorated_item = Odk::DecoratorFactory.decorate(item)
          if item.is_a?(QingGroup)
            # Iterate over repeat instances (if any)
            Array.wrap(data[item] || {}).each do |instance|
              xml << "<grp#{item.id}><header/>"
              subitems.each do |subitem, _|
                next unless instance[subitem]
                decorated_subitem = Odk::DecoratorFactory.decorate(subitem)
                xml << "<#{decorated_subitem.odk_code}>"
                xml << instance[subitem]
                xml << "</#{decorated_subitem.odk_code}>"
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

  ###############################################################################
  # These last two methods should be removed when the spec is refactored to use
  # the newer method of constructing XML fixtures. See ODK parser specs.
  ###############################################################################

  # Gets an OrderedHash of the following form for the descendants of a form.
  def arrange_descendants(form)
    sort = "(case when ancestry is null then 0 else 1 end), ancestry, rank"
    # We eager load questions and option sets since they are likely to be needed.
    nodes = form.descendants.includes(question: {option_set: :root_node}).order(sort).to_a
    with_self = Questioning.arrange_nodes(nodes)
    with_self.keys
  end

  # Arrange array of nodes into a nested hash of the form
  # {node => children}, where children = {} if the node has no children
  def arrange_nodes(nodes)
    arranged = ActiveSupport::OrderedHash.new
    min_depth = Float::INFINITY
    index = Hash.new { |h, k| h[k] = ActiveSupport::OrderedHash.new }

    nodes.each do |node|
      children = index[node.id]
      index[node.parent_id][node] = children

      depth = node.depth
      if depth < min_depth
        min_depth = depth
        arranged.clear
      end
      arranged[node] = children if depth == min_depth
    end

    arranged
  end
end
