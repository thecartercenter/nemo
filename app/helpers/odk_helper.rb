module OdkHelper
  IR_QUESTION = "ir01"   # incomplete response question
  IR_CODE     = "ir02"   # incomplete response code

  # given a Subquestion object, builds an odk <input> tag
  # calls the provided block to get the tag content
  def odk_input_tag(qing, cur_subq, &block)
    opts = {}
    opts[:ref] = "/data/#{cur_subq.odk_code}"
    opts[:rows] = 5 if cur_subq.qtype_name == "long_text"
    opts[:query] = multi_level_option_nodeset_ref(qing, cur_subq) if qing.qtype.name == 'select_one'
    content_tag(cur_subq.odk_tag, opts, &block)
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
  # E.g. instance('os16')/root/item or
  #      instance('os16')/root/item[parent_id=/data/q2_1] or
  #      instance('os16')/root/item[parent_id=/data/q2_2]
  def multi_level_option_nodeset_ref(qing, cur_subq)
    filter = if cur_subq.first_rank?
      ''
    else
      code = cur_subq.odk_code(previous: true)
      "[parent_id=/data/#{code}]"
    end
    "instance('os#{qing.option_set_id}')/root/item#{filter}"
  end
end
