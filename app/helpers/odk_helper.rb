module OdkHelper
  IR_QUESTION = "ir01"   # incomplete response question
  IR_CODE     = "ir02"   # incomplete response code

  # given a Subqing object, builds an odk <input> tag
  # calls the provided block to get the tag content
  def odk_input_tag(qing, subq, grid_mode, label_row, group = nil, xpath_prefix, &block)
    opts ||= {}
    opts[:ref] = [xpath_prefix, subq.try(:odk_code)].compact.join("/")
    opts[:rows] = 5 if subq.qtype_name == "long_text"
    if !subq.first_rank? && subq.qtype.name == "select_one"
      opts[:query] = multilevel_option_nodeset_ref(qing, subq, group.try(:odk_code), xpath_prefix)
    end
    opts[:appearance] = odk_input_appearance(qing, grid_mode, label_row)
    opts[:mediatype] = odk_media_type(subq) if subq.qtype.multimedia?
    content_tag(odk_input_tagname(subq), opts, &block)
  end

  def odk_input_appearance(qing, grid_mode, label_row)
    return "label" if label_row
    return "list-nolabel" if grid_mode

    case qing.qtype_name
    when "annotated_image"
      "annotate"
    when "sketch"
      "draw"
    when "signature"
      "signature"
    when "counter"
      params = ActiveSupport::OrderedHash.new
      params[:form_id] = "'#{qing.form_id}'"
      params[:form_name] = "'#{qing.form_name}'"
      params[:question_id] = "'#{qing.odk_code}'"
      params[:question_name] = "'#{qing.code}'" # Code instead of title because it's not locale dependent
      params[:increment] = "true()" if qing.auto_increment?
      str = params.map { |k, v| "#{k}=#{v}" }.join(", ")
      "ex:org.opendatakit.counter(#{str})".html_safe
    end
  end

  def odk_input_tagname(subq)
    if subq.qtype.name == "select_one" && subq.first_rank?
      :select1
    elsif subq.qtype.name == "select_multiple"
      :select
    elsif subq.qtype.multimedia?
      :upload
    else
      :input
    end
  end

  def odk_media_type(subq)
    case subq.qtype.name
    when "image", "annotated_image", "sketch", "signature"
      "image/*"
    when "audio"
      "audio/*"
    when "video"
      "video/*"
    end
  end

  def data_tag(form, style, &block)
    if style == "commcare"
      content_tag(
        "data",
        {
          "xmlns:jrm" => "http://dev.commcarehq.org/jr/xforms",
          "xmlns" => "http://openrosa.org/formdesigner/#{form.id}",
          "id" => "#{form.id}",
          "uiVersion" => "1",
          "version" => "#{form.current_version.code}",
          "name" => "#{form.full_name}"
        },
        &block
      )
    else
      content_tag(
        "data",
        {
          "id" => "#{form.id}",
          "version" => "#{form.current_version.code}"
        },
        &block
      )
    end
  end

  # if a question is required, then determine the appropriate value based off of if the form allows incomplete responses
  def required_value(form)
    # if form allows incompletes, question is required only if the answer to 'are there missing answers' is 'no'
    form.allow_incomplete? ? "selected(/data/#{IR_QUESTION}, 'no')" : "true()"
  end

  # generator for binding portion of xml.
  # note: _required is used to get around the 'required' html attribute
  def question_binding(form, qing, subq, group: nil, xpath_prefix: "/data")
    attribs = {
      "nodeset" => [xpath_prefix, subq.try(:odk_code)].compact.join("/"),
      "type" => binding_type_attrib(subq),
      "_required" => qing.required? && qing.visible? && subq.first_rank? ? required_value(form) : nil,
      "_readonly" => qing.has_default? && qing.read_only? ? "true()" : nil,
      "relevant" => qing.has_condition? ? Odk::DecoratorFactory.decorate(qing.condition).to_odk : nil,
      "constraint" => subq.odk_constraint,
      "jr:constraintMsg" => subq.min_max_error_msg,
      "calculate" => qing.has_default? ? DefaultParser.new(qing).to_odk.html_safe : nil,
      "jr:preload" => qing.jr_preload,
      "jr:preloadParams" => qing.jr_preload_params
    }
    attribs.reject! { |_, v| v.nil? }
    tag(:bind, attribs).gsub(/_required=/, "required=").
      gsub(/_readonly=/, "readonly=").html_safe
  end

  # note: _readonly is used to get around the 'readonly' html attribute
  def note_binding(group, xpath_prefix)
    tag(:bind, {
      "nodeset" => "#{xpath_prefix}/#{group.odk_code}-header",
      "_readonly" => "true()",
      "type" => "string"
    }.reject { |k,v| v.nil? }).gsub(/_readonly=/, "readonly=").html_safe
  end

  def binding_type_attrib(subq)
    # ODK wants non-first-level selects to have type 'string'
    subq.first_rank? ? subq.odk_name : "string"
  end

  # binding for incomplete response question
  # note: required is an html attribute. the gsub gets around this processing branch
  def ir_question_binding(_form)
    tag("bind", {
      "nodeset" => "/data/#{IR_QUESTION}",
      "required" => "true()",
      "type" => "select1",
    }.reject { |k,v| v.nil? }).gsub(/"required"/, '"true()"').html_safe
  end

  # binding for incomplete response code
  # note: required is an html attribute. the gsub gets around this processing branch
  def ir_code_binding(form)
    tag("bind", {
      "nodeset" => "/data/#{IR_CODE}",
      "required" => "true()",
      "relevant" => "selected(/data/#{IR_QUESTION}, 'yes')",
      "constraint" => ". = '#{form.override_code}'",
      "type" => "string",
    }.reject { |k,v| v.nil? }).gsub(/"required"/, '"true()"').html_safe
  end

  # For the given subqing, returns an xpath expression for the itemset tag nodeset attribute.
  # E.g. instance('os16')/root/item or
  #      instance('os16')/root/item[parent_id=/data/q2_1] or
  #      instance('os16')/root/item[parent_id=/data/q2_2]
  def multilevel_option_nodeset_ref(qing, cur_subq, group_code = nil, xpath_prefix)
    filter = if cur_subq.first_rank?
      ""
    else
      code = cur_subq.odk_code(previous: true)
      path = [xpath_prefix, code].compact.join("/")
      "[parent_id=#{path}]"
    end
    "instance('os#{qing.option_set_id}')/root/item#{filter}"
  end

  # Returns <text> tags for all first-level options.
  def odk_option_translations(form, lang)
    odk_options = form.all_first_level_option_nodes.collect do |on|
      content_tag(:text, id: "on#{on.id}") do
        content_tag(:value) do
          on.option.name(lang, strict: false)
        end
      end
    end
    odk_options.reduce(&:concat)
  end

  # The general structure for a group is:
  # group tag
  #   label
  #   repeat (if repeatable group)
  #     body
  #
  # The general structure for a fragment is:
  # group tag with field-list
  #   hint
  #   questions
  def odk_group_or_fragment(node, xpath_prefix)
    # No need to render empty groups/fragments
    return "" if node.is_childless?

    xpath = "#{xpath_prefix}/#{node.odk_code}"
    odk_group_or_fragment_wrapper(node, xpath) do
      fragments = Odk::QingGroupPartitioner.new.fragment(node)
      if fragments
        fragments.map { |f| odk_group_or_fragment(f, xpath_prefix) }.reduce(:<<)
      else
        # If appropriate for one-screen rendering, we render the group as a field-list.
        # We also include the hint.
        # In the case of fragments, this means we include hint each time, which is correct.
        # This covers the case where `node` is a fragment, because fragments should always
        # be shown on one screen since that's what they're for.
        # If one screen is not appropriate is false, we just render the hint
        # as there is no need for the group tag.
        conditional_tag(:group, node.one_screen_appropriate?, appearance: "field-list") do
          odk_group_hint(node, xpath) << odk_group_body(node, xpath)
        end
      end
    end
  end

  def odk_group_or_fragment_wrapper(node, xpath, &block)
    if node.fragment?
      # Fragments need no outer wrapper, they will get wrapped by field-list further in.
      capture(&block)
    else
      # Groups should get wrapped in a group tag and include the label.
      # Also a repeat tag if the group is repeatable
      content_tag(:group) do
        content_tag(:label, node.group_name) <<
        conditional_tag(:repeat, node.repeatable?, nodeset: xpath) do
          capture(&block)
        end
      end
    end
  end

  def odk_group_hint(node, xpath)
    if node.no_hint?
      "".html_safe
    else
      content_tag(:input, ref: "#{xpath}/#{node.odk_code}-header") do
        tag(:hint, ref: "jr:itext('#{node.odk_code}-header:hint')")
      end
    end
  end

  def odk_group_body(node, xpath)
    render("forms/odk/group_body", node: node, xpath: xpath)
  end

  # Tests if all items in the group are Questionings with the same type and option set.
  def odk_grid_mode?(group)
    items = group.sorted_children
    return false if items.size <= 1 || !group.one_screen?

    items.all? do |i|
      i.is_a?(Questioning) &&
        i.qtype_name == "select_one" &&
        i.option_set == items[0].option_set &&
        !i.multilevel?
    end
  end

  def empty_qing_group?(subtree)
    subtree.keys.empty?
  end

  def organize_qing_groups(descendants)
    QingGroupOdkPartitioner.new(descendants).fragment
  end
end
