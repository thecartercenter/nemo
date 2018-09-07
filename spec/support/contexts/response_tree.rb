# frozen_string_literal: true

# Provides spec helper methods for dealing with hierarchy of response nodes
shared_context "response tree" do
  # Checks that the given node is a valid root node for the given form.
  def expect_root(node, form)
    expect(node).to be_a(AnswerGroup)
    expect(node).to be_root
    expect(node.form_item).to eq(form.root_group)
    expect(node.new_rank).to eq(0)
  end

  def expect_children(node, types, qing_ids, values = nil)
    children = node.children.sort_by(&:new_rank)
    expect(children.map(&:type)).to eq types
    expect(children.map(&:questioning_id)).to eq qing_ids
    expect(children.map(&:new_rank)).to eq((0...children.size).to_a)
    expect(children.map(&:rank)).to eq((1...(children.size + 1)).to_a) if node.is_a?(AnswerSet)

    # This expectation can be removed when we remove the old inst_num and rank columns.
    # If child's grandparent is an AnswerGroupSet, it's in a rpt grp. inst num should match parent's rank + 1
    if node.parent.is_a?(AnswerGroupSet)
      expect(children.map(&:inst_num)).to eq(Array.new(children.size, node.new_rank + 1))
    end
    expect(children.map(&:inst_num)).to eq(Array.new(children.size, node.inst_num)) if node.is_a?(AnswerSet)

    return if values.nil?

    child_values = children.map { |child| child.is_a?(Answer) ? child.casted_value : nil }
    expect(child_values).to eq values
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

    case qing(path).qtype_name
    when "long_text"
      fill_in_trumbowyg("#" + selector, opts)
    else
      fill_in(selector, opts)
    end
  end

  def expect_path(path, options = {})
    selector = path.join(" .children ")
    expect(page).to have_selector(selector, options)
  end

  def expect_value(path, expected_value)
    actual_value =
      case qing(path).qtype_name
      when "select_one"
        el = page.find("#" + path_selector(path, "option_node_id"), visible: :all)
        OptionNode.find(el.value).option_name if el.value
      else
        page.find("#" + path_selector(path, "value"), visible: :all).value
      end

    expect(actual_value).to eq expected_value
  end

  def qing(path)
    selector = "#" + path_selector(path, "questioning_id")
    qing_id = page.find(selector, visible: :all).value
    FormItem.find(qing_id)
  end

  def expect_not_persisted(qing_id)
    expect(page).to_not have_selector("[data-qing-id='#{qing_id}']")
  end

  def expect_image(path, qing_id)
    path_selector = "[data-path='#{path.join('-')}']"
    qing_selector = "[data-qing-id='#{qing_id}']"
    image_selector = "#{path_selector}#{qing_selector}[data-qtype-name=image]"
    expect(page).to have_selector("#{image_selector} .media-thumbnail img")
  end
end
