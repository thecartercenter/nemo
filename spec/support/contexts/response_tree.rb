# frozen_string_literal: true

# Provides spec helper methods for dealing with hierarchy of response nodes
shared_context "response tree" do
  include_context "trumbowyg"

  # Checks that the given node is a valid root node for the given form.
  def expect_root(node, form)
    expect(node).to be_a(AnswerGroup)
    expect(node).to be_root
    expect(node.form_item).to eq(form.root_group)
    expect(node.new_rank).to eq(0)
  end

  # Checks response node children. Assumes they are persisted. Reloads the given node to ensure
  # persisted properly.
  def expect_children(node, types, qing_ids, values = nil)
    node = ResponseNode.find(node.id)
    expect_built_children(node, types, qing_ids, values)

    # This check exercises the hierarchy data whereas the above only exercise parent_id.
    expect(node.c[0].ancestor_ids.first).to eq(node.id) if node.c[0]
  end

  # Doesn't reload the children or test any hierarchy data. Designed for testing children in memory
  # but not persisted.
  def expect_built_children(node, types, qing_ids, values = nil)
    children = node.children.sort_by(&:new_rank)
    expect(children.map(&:type)).to eq(types)
    expect(children.map(&:questioning_id)).to eq(qing_ids)
    expect(children.map(&:new_rank)).to eq((0...children.size).to_a)
    expect(children.map(&:parent_id).uniq).to eq([node.id])

    return if values.nil?

    child_values = children.map { |child| child.is_a?(Answer) ? child.casted_value : nil }
    expect(child_values).to eq(values)
  end

  # Builds a hash for an answer node in a web response's hash representation of an answer heirarchy
  def web_answer_hash(q_id, values, relevant: "true", destroy: nil, id: "")
    hash = {
      id: id,
      type: "Answer",
      questioning_id: q_id,
      _relevant: relevant
    }.merge(values)
    hash[:_destroy] = destroy unless destroy.nil?
    hash
  end

  # Builds a hash for an answer group node in a web response's hash representation of an answer heirarchy
  def web_answer_group_hash(q_id, children, relevant: "true", destroy: nil, id: "")
    hash = {
      id: id,
      type: "AnswerGroup",
      questioning_id: q_id,
      _relevant: relevant,
      children: children
    }
    hash[:_destroy] = destroy unless destroy.nil?
    hash
  end

  def path_selector(indices, suffix = "value")
    path = ["children"] + indices.zip(["children"] * (indices.length - 1)).flatten.compact
    "response_root_#{path.join('_')}_#{suffix}"
  end

  def fill_in_question(path, opts)
    selector = path_selector(path, "value")
    value = opts[:with]

    case qing(path).qtype_name
    when "long_text"
      fill_in_trumbowyg("#" + selector, opts)
    when "select_one"
      if value.is_a?(Array)
        value.each_with_index do |text, i|
          id = path_selector(path + [i], "option_node_id")
          find("##{id} option", text: text)
          select(text, from: id)
        end
      else
        select(value, from: path_selector(path, "option_node_id"))
      end
    when "select_multiple"
      qing(path).options.each_with_index do |o, i|
        id = path_selector(path, "choices_attributes_#{i}_checked")
        value.include?(o.name) ? check(id) : uncheck(id)
      end
    when "datetime", "date", "time"
      t = Time.zone.parse(value)
      qtype_name = qing(path).qtype_name
      unless qtype_name == "time"
        control_for_temporal(path, qtype_name, :year).select(t.strftime("%Y"))
        control_for_temporal(path, qtype_name, :month).select(t.strftime("%b"))
        control_for_temporal(path, qtype_name, :day).select(t.day.to_s)
      end
      unless qtype_name == "date"
        control_for_temporal(path, qtype_name, :hour).select(t.strftime("%H"))
        control_for_temporal(path, qtype_name, :minute).select(t.strftime("%M"))
        control_for_temporal(path, qtype_name, :second).select(t.strftime("%S"))
      end
    else
      fill_in(selector, opts)
    end
  end

  def expect_path(path, options = {})
    selector = path.join(" .children ")
    expect(page).to have_selector(selector, options)
  end

  def expect_value(path, expected_value)
    case qing(path).qtype_name
    when "select_multiple"
      qing(path).options.each do |o|
        if expected_value.include?(o.name)
          expect(page.has_checked_field?(o.name)).to eq(true), "Expected #{o.name} to be checked"
        else
          expect(page.has_unchecked_field?(o.name)).to eq(true), "Expected #{o.name} to NOT be checked"
        end
      end
    when "datetime", "date", "time"
      qtype_name = qing(path).qtype_name
      t = Time.zone.parse(expected_value)
      unless qtype_name == "time"
        expect(control_for_temporal(path, qtype_name, :year).value).to eq(t.strftime("%Y"))
        expect(control_for_temporal(path, qtype_name, :month)
          .find("option[selected]").text).to eq(t.strftime("%b"))
        expect(control_for_temporal(path, qtype_name, :day).value).to eq(t.day.to_s)
      end
      unless qtype_name == "date"
        expect(control_for_temporal(path, qtype_name, :hour).value).to eq(t.strftime("%H"))
        expect(control_for_temporal(path, qtype_name, :minute).value).to eq(t.strftime("%M"))
        expect(control_for_temporal(path, qtype_name, :second).value).to eq(t.strftime("%S"))
      end
    when "select_one"
      el = page.find("#" + path_selector(path, "option_node_id"), visible: :all)
      OptionNode.find(el.value).name if el.value
    else
      actual_value = page.find("#" + path_selector(path, "value"), visible: :all).value
      expect(actual_value).to eq(expected_value)
    end
  end

  def qing(path)
    selector = "#" + path_selector(path, "questioning_id")
    qing_id = page.find(selector, visible: :all).value
    FormItem.find(qing_id)
  end

  def expect_not_persisted(qing_id)
    expect(page).to_not(have_selector("[data-qing-id='#{qing_id}']"))
  end

  def expect_image(path, qing_id)
    path_selector = "[data-path='#{path.join('-')}']"
    qing_selector = "[data-qing-id='#{qing_id}']"
    image_selector = "#{path_selector}#{qing_selector}[data-qtype-name=image]"
    expect(page).to have_selector("#{image_selector} .media-thumbnail img")
  end

  def visit_new_response_page
    visit(new_response_path(
      locale: "en",
      mode: "m",
      mission_name: get_mission.compact_name,
      form_id: form.id
    ))
  end

  def fill_and_expect_visible(path, value, visible)
    fill_in_question(path, with: value)
    expect_visible(visible)
  end

  # visible_fields should be an array of node paths
  def expect_visible(visible_fields)
    visible_fields.each do |path|
      path_selector = path.join("-")
      node_selector = %(.node[data-path="#{path_selector}"])
      msg = "Expected #{path.join('-')} to be visible, but is hidden."
      expect(find(node_selector)).to be_visible, -> { msg }
    end
  end

  def expect_read_only_value(path, value)
    el = page.find("[data-path='#{path.join('-')}']")
    expect(el).to have_content(value)
  end

  def temporal_mapping
    {year: "1i", month: "2i", day: "3i", hour: "4i", minute: "5i", second: "6i"}
  end

  def control_for_temporal(path, type, subfield)
    find("##{path_selector(path, "#{type}_value_#{temporal_mapping[subfield]}")}")
  end
end
