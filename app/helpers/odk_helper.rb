module OdkHelper
  IR_QUESTION = "ir01"   # incomplete response question
  IR_CODE     = "ir02"   # incomplete response code

  # if a question is required, then determine the appropriate value based off of if the form allows incomplete responses
  def required_value(form)
    # if form allows incompletes, question is required only if the answer to 'are there missing answers' is 'no'
    form.allow_incomplete? ? "selected(/data/#{IR_QUESTION}, 'no')" : "true()"
  end

  # generator for binding portion of xml.
  # note: _required is used to get around the 'required' html attribute
  def question_binding(form, q)
    tag("bind", {
      'nodeset' => "/data/#{q.question.odk_code}",
      'type' => q.question.qtype.odk_name,
      '_required' => q.required? ? required_value(form) : nil,
      'relevant' => q.has_condition? ? q.condition.to_odk : nil,
      'constraint' => q.odk_constraint,
      'jr:constraintMsg' => q.question.min_max_error_msg,
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
end

