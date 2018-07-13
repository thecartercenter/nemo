# frozen_string_literal: true

module OdkHelper
  # given a Subqing object, builds an odk <input> tag
  # calls the provided block to get the tag content
  def odk_input_tag(qing, subq, grid_mode, label_row, group = nil, xpath_prefix, &block)
    opts ||= {}
    suffix =
      if label_row
        # We can't bind to the question's node here or, if the question is required,
        # we won't be allowed to proceed since it won't be possible to fill in the question.
        # Also, this question will appear again in a regular row so it would be weird
        # to link it to the same instance node twice.
        # Instead we use the parent group's header node.
        "header"
      else
        subq.try(:odk_code)
      end
    opts[:ref] = [xpath_prefix, suffix].compact.join("/")
    opts[:rows] = 5 if subq.qtype_name == "long_text"
    if !subq.first_rank? && subq.qtype.name == "select_one"
      opts[:query] = multilevel_option_nodeset_ref(qing, subq, xpath_prefix)
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
          "id" => form.id.to_s,
          "uiVersion" => "1",
          "version" => form.current_version.code.to_s,
          "name" => form.full_name.to_s
        },
        &block
      )
    else
      content_tag(
        "data",
        {
          "id" => form.id.to_s,
          "version" => form.current_version.code.to_s
        },
        &block
      )
    end
  end

  # For the given subqing, returns an xpath expression for the itemset tag nodeset attribute.
  # E.g. instance('os16')/root/item or
  #      instance('os16')/root/item[parent_id=/data/q2_1] or
  #      instance('os16')/root/item[parent_id=/data/q2_2]
  def multilevel_option_nodeset_ref(qing, cur_subq, xpath_prefix)
    filter = if cur_subq.first_rank?
               ""
             else
               code = cur_subq.odk_code(options: {previous: true})
               path = [xpath_prefix, code].compact.join("/")
               "[parent_id=#{path}]"
    end
    "instance('#{Odk::CodeMapper.instance.code_for_item(qing.option_set)}')/root/item#{filter}"
  end

  # Returns <text> tags for all first-level options.
  def odk_option_translations(form, lang)
    option_nodes = form.all_first_level_option_nodes
    # sort these deterministically for the test suite when needed, order does not matter for ODK
    option_nodes.sort_by! { |on| [on.option_set.name, on.option_name] } if Rails.env.test?
    odk_options = option_nodes.map do |on|
      content_tag(:text, id: Odk::CodeMapper.instance.code_for_item(on)) do
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
        odk_inner_group_tag(node) do
          # We include the hint here.
          # In the case of fragments, this means we include hint each time, which is correct.
          # This covers the case where `node` is a fragment, because fragments should always
          # be shown on one screen since that's what they're for.
          odk_group_item_name(node, xpath) << odk_group_hint(node, xpath) << odk_group_body(node, xpath)
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
        tag(:label, ref: "jr:itext('#{node.odk_code}:label')") <<
          conditional_tag(:repeat, node.repeatable?, nodeset: xpath) do
            capture(&block)
          end
      end
    end
  end

  # Sometimes we need a second, inner group tag. There are two possible reasons:
  #
  # 1. It's a repeat group, in which case the item label goes inside the inner group.
  # 2. It's a one_screen group, in which case we need to set appearance="field-list"
  #
  # Note both can be true at once.
  def odk_inner_group_tag(node, &block)
    do_inner_tag = node.one_screen_appropriate? || node.repeatable?
    appearance = node.one_screen_appropriate? ? "field-list" : nil
    conditional_tag(:group, do_inner_tag, appearance: appearance) do
      capture(&block)
    end
  end

  def odk_group_hint(node, xpath)
    if node.no_hint?
      "".html_safe
    else
      content_tag(:input, ref: "#{xpath}/header") do
        tag(:hint, ref: "jr:itext('#{node.odk_code}:hint')")
      end
    end
  end

  def odk_group_item_name(node, _xpath)
    # Group item name should only be present for repeatable qing groups.
    if node.respond_to?(:group_item_name) && node.group_item_name && !node.group_item_name.empty?
      tag(:label, ref: "jr:itext('#{node.odk_code}:itemname')")
    else
      "".html_safe
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
