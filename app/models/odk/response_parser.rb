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
      puts "********end of build_answer_tree:**********"
      puts response.root_node.debug_tree
    end

    def add_level(xml_node, form_node, response_node)
      puts "Add level: #{xml_node.name}, content: #{xml_node.content}"
      xml_node.elements.each_with_index do |child, index|
        name = child.name
        content = child.content
        unless node_is_odk_header(child)
          puts "Add sibling: #{name} #{content}"
          form_item = form_item(name)
          if form_item.class == QingGroup && form_item.repeatable?
            add_repeat_group(child, form_item, response_node)
          elsif form_item.class == QingGroup
            add_group(child, form_item, response_node)
          else
            add_answer(content, form_item, response_node)
          end
        end
      end
    end

    def add_repeat_group(xml_node, form_item, parent)
      puts "Add repeat group: #{xml_node.name}, content: #{xml_node.content}"
      puts parent.root? ? parent.debug_tree : parent.root.debug_tree

      group_set = find_or_create_group_set(form_item, parent)
      #puts "in add_repeat_group: num_children: #{group_set.c.count} #{group_set.debug_tree}"
      add_group(xml_node, form_item, group_set)
    end

    def find_or_create_group_set(form_item, parent)

      group_set = parent.c.find do |c|
        c.questioning_id == form_item.id && c.class == AnswerGroupSet
      end
      if group_set.nil?
        puts "add group set"
        puts "======= before group set: ========"
        puts parent.root? ? parent.debug_tree : parent.root.debug_tree
        group_set = AnswerGroupSet.new(questioning_id: form_item.id, new_rank: form_item.rank)
        parent.children << group_set
        puts "======= after adding group set: ========"
        puts  parent.root? ? parent.debug_tree : parent.root.debug_tree
      else
        puts "group set already exists: num_children: #{group_set.c.count} #{group_set.debug_tree}"
      end

      group_set
    end

    def add_group(xml_node, form_item, parent)
      puts "parent children count: #{parent.c.count}"
      puts "add group: #{xml_node.name}, content: #{xml_node.content}, rank: #{parent.c.count + 1}"
      puts  parent.debug_tree
      unless node_is_odk_header(xml_node)
        group = AnswerGroup.new(
          questioning_id: form_item.id,
          new_rank: parent.c.count + 1 #QUESTION THIS SEEMS DICEY!
        )
        parent.children << group
        add_level(xml_node, form_item, group)
      end
    end

    def add_answer(content, form_item, parent)
      puts "add answer: #{content}"
      puts parent.ancestry_path
      answer = Answer.new(
        questioning_id: form_item.id,
        value: content,
        new_rank: parent.c.count + 1 #QUESTION THIS SEEMS DICEY!
      )
      parent.children << answer
    end

    def node_is_odk_header(node)
      /\S*header/.match(node.name).present?
    end

    def form_item(name)
      form_item_id = form_item_id_from_tag(name)
      unless FormItem.exists?(form_item_id)
        raise SubmissionError.new("Submission contains unidentifiable group or question.")
      end
      form_item = FormItem.find(form_item_id)
      unless form_item.form_id == response.form.id
        raise SubmissionError.new("Submission contains group or question not found in form.")
      end
      form_item
    end

    #TODO: refactor mapping to one shared place accessible here and from odk decorators
    def form_item_id_from_tag(tag)
      prefixes = %w[qing grp]
      prefixes.each do |p|
        if /#{Regexp.quote(p)}\S*/.match?(tag)
          return tag.remove p
        end
      end
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
