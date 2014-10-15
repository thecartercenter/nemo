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
      'relevant' => relevance_expression(qing, subq),
      'constraint' => subq.odk_constraint,
      'jr:constraintMsg' => subq.min_max_error_msg,
     }.reject{|k,v| v.nil?}).gsub(/_required=/, 'required=').html_safe
  end

  def relevance_expression(qing, subq)
    expr = [].tap do |chunks|
      chunks << qing.condition.to_odk if qing.has_condition?
      unless subq.first_rank?
        # For levels 2+ of a multilevel question, don't show it if its nodeset is empty OR
        # there is a 'blank' tag in the nodeset, indicating that it is really blank
        # even though it contains a placeholder to keep ODK happy.
        nodeset = multi_level_option_nodeset_ref(qing, subq)
        chunks << "count(#{nodeset}) > 0"
        chunks << "count(#{nodeset}/blank) = 0"
      end
    end.map{ |c| "(#{c})" }.join(' and ')
    expr.empty? ? nil : expr
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
  # E.g. instance('option_set_2')/options/opt or
  #      instance('option_set_2')/options/opt[value=/data/q2_1]/opt or
  #      instance('option_set_2')/options/opt[value=/data/q2_1]/opt[value=/data/q2_2]/opt
  def multi_level_option_nodeset_ref(qing, cur_subq)
    instance_ref = "instance('option_set_#{qing.option_set_id}')"
    "#{instance_ref}/options/".tap do |ref|
      qing.subquestions.each do |subq|
        ref << 'opt'
        if subq == cur_subq
          break
        else
          ref << "[value=/data/#{subq.odk_code}]/"
        end
      end
    end
  end

  # Renders the given OptionNode as XML for use with ODK, etc.
  def option_node_as_xml(option_set, node, depth = 0, path = [1])
    id = node.option_id
    "".tap do |xml|
      xml << "<value>#{id}</value><key>option#{id}</key>".html_safe unless node.root?

      if node.has_children?
        # Recursive step.
        xml << node.sorted_children.each_with_index.map do |c, i|
          content_tag(:opt, option_node_as_xml(option_set, c, depth + 1, path + [i+1]))
        end.join.html_safe
      else
        # If node has no children and we're on the first branch of the tree,
        # we need to ensure the branch extends to the max depth of the tree. Otherwise ODK complains.
        if path.uniq == [1] && (depth_diff = option_set.max_depth - depth) > 0
          dummy_nodes = ''
          depth_diff.times do
            dummy_nodes = "<opt><value></value><blank></blank><key>blankoption</key>#{dummy_nodes}</opt>"
          end
          xml << dummy_nodes
        end
      end

    end.html_safe
  end
end
