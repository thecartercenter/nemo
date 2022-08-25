# frozen_string_literal: true

module ODK
  # Takes a response and odk data. Parses odk data into answer tree for response.
  # Returns the response because in the case of multimedia, the parser may replace
  # the response object the controller passes in with an
  # existing response from the database.
  class ResponseParser
    attr_accessor :response, :raw_odk_xml, :files, :awaiting_media, :odk_hash

    def initialize(response: nil, files: nil, awaiting_media: false)
      raise "Submissions must have a mission" if response.mission.nil?
      @response = response
      @raw_odk_xml = files.delete(:xml_submission_file).read
      @files = files
      # Default to odk for legacy usage; newer code may explicitly specify "enketo" instead.
      @response.source ||= "odk"
      @awaiting_media = awaiting_media
      @answer_parser = nil
    end

    # populates response tree and saves
    def populate_response
      process_xml(raw_odk_xml)
      response
    end

    private

    # Generates and saves a hash of the complete XML so that multi-chunk media form submissions
    # can be uniquely identified and handled
    def calculate_odk_hash
      odk_hash || Digest::SHA256.base64digest(raw_odk_xml)
    end

    def process_xml(raw_odk_xml)
      data = Nokogiri::XML(raw_odk_xml).root
      raise SubmissionError, "invalid XML" if data.nil?
      lookup_and_check_form(data["id"], data["version"])
      if existing_response
        answer_parser.add_media_to_existing_response
      else
        response.odk_hash = awaiting_media ? calculate_odk_hash : nil
        build_answer_tree(data)
      end
    end

    def answer_parser
      @answer_parser ||= ODK::AnswerParser.new(response, files)
    end

    def build_answer_tree(data)
      response.root_node = AnswerGroup.new(
        response: response,
        questioning_id: response.form.root_id,
        new_rank: 0
      )
      add_level(data, response.root_node)
    end

    def add_level(xml_node, response_node)
      xml_node.elements.each do |child|
        unless node_is_odk_header?(child)
          if node_is_ir_question?(child)
            response.incomplete = child.content == "yes"
          elsif CodeMapper.instance.item_code?(child.name)
            add_response_node(child, response_node)
          end
        end
      end
    end

    # We use the form item to determine the node type because ODK XML does not
    # tell us what type a node is.
    def add_response_node(node, response_node)
      form_item = form_item(node.name)
      if form_item.class == QingGroup && form_item.repeatable?
        add_repeat_group(node, form_item, response_node)
      elsif form_item.class == QingGroup
        add_group(node, form_item, response_node)
      elsif form_item.multilevel?
        add_answer_set_member(node, form_item, response_node)
      else
        add_answer(node.content, form_item, response_node)
      end
    end

    def node_is_ir_question?(node)
      node.name == ODK::FormDecorator::IR_QUESTION
    end

    def node_is_odk_header?(node)
      /\S*header/.match(node.name).present?
    end

    def new_node(type, form_item, parent)
      type.new(
        questioning_id: form_item.id,
        new_rank: parent.children.length,
        response: response
      )
    end

    # Rank will go away at end of answer refactor
    def rank(parent)
      parent.is_a?(AnswerSet) ? parent.children.length + 1 : 1
    end

    def add_answer_set_member(xml_node, form_item, parent)
      answer_set = find_or_create_answer_set(form_item, parent)
      add_answer(xml_node.content, form_item, answer_set)
    end

    def find_or_create_answer_set(form_item, parent)
      answer_set = parent.c.find do |c|
        c.questioning_id == form_item.id && c.class == AnswerSet
      end
      if answer_set.nil?
        answer_set = new_node(AnswerSet, form_item, parent)
        parent.children << answer_set
      end
      answer_set
    end

    def add_repeat_group(xml_node, form_item, parent)
      group_set = find_or_create_group_set(form_item, parent)
      add_group(xml_node, form_item, group_set)
    end

    def find_or_create_group_set(form_item, parent)
      group_set = parent.c.find do |c|
        c.questioning_id == form_item.id && c.class == AnswerGroupSet
      end
      if group_set.nil?
        group_set = new_node(AnswerGroupSet, form_item, parent)
        parent.children << group_set
      end
      group_set
    end

    def add_group(xml_node, form_item, parent)
      return if node_is_odk_header?(xml_node)
      group = new_node(AnswerGroup, form_item, parent)
      parent.children << group
      add_level(xml_node, group)
    end

    def add_answer(content, form_item, parent)
      answer = new_node(Answer, form_item, parent)
      answer_parser.populate_answer_value(answer, content, form_item)
      parent.children << answer
    end

    def form_item(name)
      form_item_id = form_item_id_from_tag(name)
      form_item = FormItem.where(mission: response.mission).find_by(id: form_item_id)
      if form_item.nil?
        raise SubmissionError, "Submission contains unidentifiable group or question '#{name}'."
      end
      unless form_item.form_id == response.form.id
        raise SubmissionError, "Submission contains group or question '#{name}' not found in form."
      end
      form_item
    end

    def form_item_id_from_tag(tag)
      ODK::CodeMapper.instance.item_id_for_code(tag)
    end

    # Checks if form ID and version were given, if form exists, and if version is correct
    def lookup_and_check_form(id, version)
      raise SubmissionError, "no form id was given" if id.nil?
      raise FormVersionError, "form version must be specified" if version.nil?
      form = response.form = Form.where(mission: response.mission).find_by(id: id)
      raise SubmissionError, "form not found in this mission" if form.nil?

      raise FormStatusError, "form is a draft" if form.draft?
      raise FormStatusError, "form is paused" if form.paused?

      raise "xml submissions must be to versioned forms" if form.current_version.nil?

      # This check for old 3-letter codes can be removed once we stop supporting them.
      if version.length == FormVersion::CODE_LENGTH
        code = version
        version_num = form.versions.find_by(code: code)&.number
        raise FormVersionError, "Form version code not found" if version_num.nil?
      else
        version_num = version
      end

      raise FormVersionError, "Form version is outdated" if version_num < form.minimum_version_number
    end

    def existing_response
      existing_response = Response.find_by(odk_hash: calculate_odk_hash, form_id: response.form_id)
      if existing_response.present?
        self.response = existing_response
        true
      else
        false
      end
    end
  end
end
