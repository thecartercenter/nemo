module Odk
  # Takes a response and odk data. Parses odk data into answer tree for response.
  class SubmissionParser

    #initialize in a similar way to xml submission
    def initialize(response: nil, files: nil)
      @response = response
      # what is awaiting_media for?
      @xml = files.delete(:xml_submission_file).read
      @files = files
      @response.source = "odk"
      populate_answer_tree(@xml)
    end

    private

    def populate_answer_tree(xml)
      data = Nokogiri::XML(xml).root
      lookup_and_check_form(id: data["id"], version: data["version"])
      #check_for_existing_response

      # Response mission should already be set
      raise "Submissions must have a mission" if @response.mission.nil?
      build_answer_tree(data, @response.form)
    end

    def build_answer_tree(data, form)
      @response.root_node = AnswerGroup.new
      add_level(data, form, @response.root_node)
    end

    def add_level(xml_node, form_node, response_node)
      xml_node.elements.each do |child|
        name = child.name
        content = child.content
        answer = Answer.new(qing: Questioning.find_by(odk_code: name).id, value: content)
        response_node.children << answer
      end
    end

    # Checks if form ID and version were given, if form exists, and if version is correct
    def lookup_and_check_form(params)
      # if either of these is nil or not an integer, error
      raise SubmissionError.new("no form id was given") if params[:id].nil?
      raise FormVersionError.new("form version must be specified") if params[:version].nil?

      # try to load form (will raise activerecord error if not found)
      # if the response already has a form, don't fetch it again
      @response.form = Form.find(params[:id]) unless @response.form.present?
      form = @response.form

      # if form has no version, error
      raise "xml submissions must be to versioned forms" if form.current_version.nil?

      puts params[:version]
      puts form.current_version.code
      # if form version is outdated, error
      raise FormVersionError.new("form version is outdated") if form.current_version.code != params[:version]
    end

    def check_for_existing_response
      response = Response.find_by(odk_hash: odk_hash, form_id: @response.form_id)
      @existing_response = response.present?
      @response = response if @existing_response
    end
  end
end
