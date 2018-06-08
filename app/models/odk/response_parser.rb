module Odk
  # Takes a response and odk data. Parses odk data into answer tree for response.
  class ResponseParser
    attr_accessor :response, :raw_odk_xml

    #initialize in a similar way to xml submission
    def initialize(response: nil, files: nil)
      @response = response
      # TODO: what is awaiting_media for?
      @raw_odk_xml = files.delete(:xml_submission_file).read
      @files = files
      @response.source = "odk"
    end

    def populate_response
      build_answers(raw_odk_xml)
    end

    private

    def build_answers(raw_odk_xml)
      data = Nokogiri::XML(raw_odk_xml).root
      lookup_and_check_form(id: data["id"], version: data["version"])
      check_for_existing_response
      # TODO: handle awaiting_media

      # Response mission should already be set - TODO: consider moving to constructor or lookup_and_check_form
      raise "Submissions must have a mission" if response.mission.nil?
      build_answer_tree(data, response.form)
    end



    def build_answer_tree(data, form)
      response.root_node = AnswerGroup.new(
        questioning_id: response.form.root_id,
        response_id: response.id
      )
      add_level(data, form, response.root_node)
    end

    def add_level(xml_node, form_node, response_node)
      xml_node.elements.each_with_index do |child, index|
        name = child.name
        content = child.content
        form_item_id = form_item_id_from_tag(name)
        check_form_item_valid(form_item_id)
        answer = Answer.new(
          questioning_id: form_item_id,
          value: content,
          new_rank: index + 1
        )
        response_node.children << answer
        response_node.debug_tree
      end
    end

    def check_form_item_valid(form_item_id)
      unless FormItem.exists?(form_item_id)
        raise SubmissionError.new("Submission contains unidentifiable group or question.")
      end
      form_item = FormItem.find(form_item_id)
      unless form_item.form_id == response.form.id
        raise SubmissionError.new("Submission contains group or question not found in form.")
      end
    end

    #TODO: refactor mapping to one shared place
    def form_item_id_from_tag(tag)
      prefix = tag.slice! "qing"
      id = tag
      id
    end

    # Checks if form ID and version were given, if form exists, and if version is correct
    def lookup_and_check_form(params)
      # if either of these is nil or not an integer, error
      raise SubmissionError.new("no form id was given") if params[:id].nil?
      raise FormVersionError.new("form version must be specified") if params[:version].nil?

      # try to load form (will raise activerecord error if not found)
      # if the response already has a form, don't fetch it again
      response.form = Form.find(params[:id]) unless response.form.present?
      form = response.form

      # if form has no version, error
      raise "xml submissions must be to versioned forms" if form.current_version.nil?

      # if form version is outdated, error
      raise FormVersionError.new("Form version is outdated") if form.current_version.code != params[:version]
    end

    def check_for_existing_response
      response = Response.find_by(odk_hash: odk_hash, form_id: @response.form_id)
      @existing_response = response.present?
      response = response if @existing_response
    end

    # Generates and saves a hash of the complete XML so that multi-chunk media form submissions
    # can be uniquely identified and handled
    def odk_hash
      @odk_hash ||= Digest::SHA256.base64digest @raw_odk_xml
    end

  end
end
