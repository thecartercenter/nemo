# frozen_string_literal: true

shared_context "hierarchical response form conditional logic" do
  include_context "trumbowyg"

  def visit_new_hierarchical_response_page
    visit(new_hierarchical_response_path(
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name,
      form_id: form.id
    ))
  end

  def fill_and_expect_visible(field, value, visible)
    fill_answer(field: field, value: value)
    expect_visible(visible)
  end

  def fill_answer(field:, value:)
    qing = qings[field.is_a?(Symbol) ? field : field[0]]
    idx = nil
    id = nil
    path = nil
    if field.is_a?(Symbol)
      idx = qings.keys.index(field)
      id = "response_root_children_#{idx}_value"
    else
      idx = qings.keys.index(field[0])
      path = [idx] + field[1]
      parts = path.zip(["children"] * (path.length - 1)).flatten.compact
      id = "response_root_children_#{parts.join('_')}_value"
    end
    within(selector_for(qing, path)) do
      case qing.qtype_name
      when "long_text"
        fill_in_trumbowyg("##{id}", with: value)
      when "select_one"
        if value.is_a?(Array)
          value.each_with_index do |o, i|
            id = "response_root_children_#{idx}_children_#{i}_option_node_id"
            find("##{id} option", text: o)
            select(o, from: id)
          end
        else
          id = "response_root_children_#{idx}_option_node_id"
          select(value, from: id)
        end
      when "select_multiple"
        qing.options.each_with_index do |o, i|
          id = "response_root_children_#{idx}_choices_attributes_#{i}_checked"
          value.include?(o.name) ? check(id) : uncheck(id)
        end
      when "datetime", "date", "time"
        t = Time.zone.parse(value)
        prefix = "response_root_children_#{idx}_#{qing.qtype_name}_value"
        unless qing.qtype_name == "time"
          select(t.strftime("%Y"), from: "#{prefix}_1i")
          select(t.strftime("%b"), from: "#{prefix}_2i")
          select(t.day.to_s, from: "#{prefix}_3i")
        end
        unless qing.qtype_name == "date"
          select(t.strftime("%H"), from: "#{prefix}_4i")
          select(t.strftime("%M"), from: "#{prefix}_5i")
          select(t.strftime("%S"), from: "#{prefix}_6i")
        end
      else
        fill_in(id, with: value)
      end
    end
  end

  # visible_fields should be an array of symbols or pairs of form [symbol, {inst: X}] where X is
  # the instance descriptor we should be looking in. If a plain symbol is passed, we assume instance 1.
  def expect_visible(visible_fields)
    # Transform visible_fields to the form {Questioning => [X, Y], ...} where X, Y are instance descriptors.
    visible_fields =
      {}.tap do |list|
        visible_fields.each do |item|
          if item.is_a?(Symbol)
            qing = qings[item]
            inst = 1
          else
            qing = qings[item[0]]
            inst = item[1]
          end
          list[qing] ||= []
          list[qing] << inst
        end
      end

    form.questionings.each do |qing|
      # Get instance count for parent instance.
      inst_count =
        if qing.depth == 1
          1
        else
          # TODO: When we add support for nested groups to this spec, we will need to refine this selector
          # to distinguish between different sets of subinstances within a parent repeat group's instances.
          page.all(%(div.qing-group-instance[data-group-id="#{qing.parent_id}"])).size
        end

      # For each instance, check visibility.
      # TODO: When we add support for nested groups to this spec, we will have to
      # respect the full instance descriptor, not just a single number.
      (1..inst_count).each do |inst|
        if (visible_fields[qing] || []).include?(inst)
          msg = "Expected #{qing.full_dotted_rank} #{qing.code} #{qing.qtype_name} to be visible, but is hidden."
          expect(find(selector_for(qing))).to be_visible, -> { msg }
        else
          msg = "Expected #{qing.full_dotted_rank} #{qing.code} #{qing.qtype_name} to be hidden, but is visible."
          expect(find(selector_for(qing), visible: false)).not_to be_visible, -> { msg }
        end
      end
    end
  end

  # Gets a CSS selector for the answer_field div described by the given qing and instance descriptor.
  def selector_for(qing, path = nil)
    if path
      path_selector = path.join("-")
      %(.node[data-qing-id="#{qing.id}"][data-path^="#{path_selector}"])
    else
      %(.node[data-qing-id="#{qing.id}"])
    end
  end
end
