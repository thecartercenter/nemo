module OdkHelper
  IR_QUESTION = "ir01"   # incomplete response question
  IR_CODE     = "ir02"   # incomplete response code

  # generator for translation portion of xml needed for incomplete response feature
  def incomplete_response_translations
    missing_answers_label + missing_answers_hint + code_label
  end

  # incomplete response translation label for missing answers question
  def missing_answers_label
    content_tag :text, :id => "#{IR_QUESTION}:label" do
      content_tag(:value, t("incomplete_response.missing_answers.label"))
    end
  end

  # incomplete response translation hint for missing answers question
  def missing_answers_hint
    content_tag :text, :id => "#{IR_QUESTION}:hint" do
      content_tag(:value, t("incomplete_response.missing_answers.hint"))
    end
  end

  # incomplete response translation label for code question
  def code_label
    content_tag :text, :id => "#{IR_CODE}:label" do
      content_tag(:value, t("incomplete_response.code_label"))
    end
  end

  # if a question is required, then determine the appropriate value based off of if the form allows incomplete responses
  def required_value(form)
    form.allow_incomplete? ? "selected(/data/#{IR_QUESTION}, '1')" : "true()"
  end

  # generator for binding portion of xml.
  # note: _required is used to get around the 'required' html attribute
  def generate_bind_xml(form, q)
    bind_output = tag("bind", {
        'nodeset' => "/data/#{q.question.odk_code}",
        'type' => q.question.qtype.odk_name,
        '_required' => q.required? ? required_value(form) : nil,
        'relevant' => q.has_condition? ? q.condition.to_odk : nil,
        'constraint' => q.odk_constraint,
        'jr:constraintMsg' => q.question.min_max_error_msg,
       }.reject{|k,v| v.nil?})
    bind_output.gsub(/_required=/, 'required=').html_safe
  end

  # generator for binding portion of xml needed for incomplete response feature
  def incomplete_response_binding(form)
    ir_question_binding(form) + ir_code_binding(form)
  end

  # binding for incomplete response question
  # note: required is an html attribute. the gsub gets around this processing branch
  def ir_question_binding(form)
    bind_output = tag("bind", {
        'constraint' => "()",
        'nodeset' => "/data/#{IR_QUESTION}",
        'required' => "true()",
        'type' => "select1",
       }.reject{|k,v| v.nil?}).gsub(/"required"/, '"true()"').html_safe
  end

  # binding for incomplete response code
  # note: required is an html attribute. the gsub gets around this processing branch
  def ir_code_binding(form)
    bind_output = tag("bind", {
        'constraint' => "()",
        'nodeset' => "/data/#{IR_CODE}",
        'required' => "true()",
        'relevant' => "selected(/data/#{IR_QUESTION}, '2')",
        'constraint' => ". = '#{form.override_code}'",
        'type' => "string",
       }.reject{|k,v| v.nil?}).gsub(/"required"/, '"true()"').html_safe
  end


  # input tag for incomplete response questions
  def incomplete_response_input_tag(odk_code, &block)
    opts = {}
    opts[:ref] = "/data/#{odk_code}"
    content_tag("input", opts, &block)
  end
end

