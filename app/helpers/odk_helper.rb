module OdkHelper
  IR_QUESTION = "ir01"   # incomplete response question
  IR_CODE     = "ir02"   # incomplete response code

  # given a Subquestion object, builds an odk <input> tag
  # calls the provided block to get the tag content
  def odk_input_tag(subq, &block)
    opts = {}
    opts[:ref] = "/data/#{subq.odk_code}"
    opts[:rows] = 5 if subq.qtype_name == "long_text"
    content_tag(subq.odk_tag, opts, &block)
  end

  # if a question is required, then determine the appropriate value based off of if the form allows incomplete responses
  def required_value(form)
    # if form allows incompletes, question is required only if the answer to 'are there missing answers' is 'no'
    form.allow_incomplete? ? "selected(/data/#{IR_QUESTION}, 'no')" : "true()"
  end

  # generator for binding portion of xml.
  # note: _required is used to get around the 'required' html attribute
  def question_binding(form, qing, subq)
    tag("bind", {
      'nodeset' => "/data/#{subq.odk_code}",
      'type' => subq.odk_name,
      '_required' => qing.required? && subq.first_rank? ? required_value(form) : nil,
      'relevant' => qing.has_condition? ? qing.condition.to_odk : nil,
      'constraint' => subq.odk_constraint,
      'jr:constraintMsg' => subq.min_max_error_msg,
     }.reject{|k,v| v.nil?}).gsub(/_required=/, 'required=').html_safe
  end

  # binding for incomplete response question
  # note: required is an html attribute. the gsub gets around this processing branch
  def ir_question_binding(form)
    tag("bind", {
      'nodeset' => "/data/#{IR_QUESTION}",
      'required' => "true()",
      'type' => "select1",
     }.reject{|k,v| v.nil?}).gsub(/"required"/, '"true()"').html_safe
  end

  # binding for incomplete response code
  # note: required is an html attribute. the gsub gets around this processing branch
  def ir_code_binding(form)
    tag("bind", {
      'nodeset' => "/data/#{IR_CODE}",
      'required' => "true()",
      'relevant' => "selected(/data/#{IR_QUESTION}, 'yes')",
      'constraint' => ". = '#{form.override_code}'",
      'type' => "string",
     }.reject{|k,v| v.nil?}).gsub(/"required"/, '"true()"').html_safe
  end

  # For the given subquestion, returns an xpath expression for the itemset tag nodeset attribute.
  # E.g. instance('option_set_16')/options/o or
  #      instance('option_set_16')/options/o[id=/data/q2_1]/o or
  #      instance('option_set_16')/options/o[id=/data/q2_1]/o[id=/data/q2_2]/o
  def multi_level_option_nodeset_ref(qing, cur_subq)
    "instance('option_set_#{qing.option_set_id}')/options/".tap do |ref|
      qing.subquestions.each do |subq|
        ref << 'o'
        if subq == cur_subq
          break
        else
          ref << "[id=/data/#{subq.odk_code}]/"
        end
      end
    end
  end

  # Renders the given hash (returned by ancestry's arrange_serializable) as XML for use with ODK, etc.
  def option_set_hash_as_xml(nodes, max_depth, depth = 0, first_child = true)
    # Special handling for root node (depth = 0)
    return option_set_hash_as_xml(nodes.first['children'], max_depth, 1) if depth == 0

    nodes.each_with_index.map do |node, i|
      xml = "<id>#{node['option_id']}</id><k>o#{node['option_id']}</k>"
      if node['children'].present?
        xml << option_set_hash_as_xml(node['children'], max_depth, depth + 1, first_child && i == 0)
      else
        # If node has no children and we're on the first branch of the tree,
        # we need to ensure the branch extends to the max depth of the tree. Otherwise ODK complains.
        if first_child && (depth_diff = max_depth - depth) > 0
          dummy_nodes = ''
          depth_diff.times do
            dummy_nodes = "<o><id></id><k>blankoption</k>#{dummy_nodes}</o>"
          end
          xml << dummy_nodes
        end
      end
      content_tag(:o, xml.html_safe)
    end.join.html_safe
  end

  def odk_option_translations(form, lang)
    content_tag(:text, tag(:value), id: 'blankoption') +
      form.all_options.map{ |o| %{<text id="o#{o.id}"><value>#{o.name(lang, strict: false)}</value></text>} }.join.html_safe
  end
end
