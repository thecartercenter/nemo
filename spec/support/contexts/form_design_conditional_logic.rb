# frozen_string_literal: true

shared_context "form design conditional logic" do
  def select_left_qing(code)
    find('select[name*="\\[left_qing_id\\]"]').select(code)
    wait_for_ajax # Changing the question triggers an ajax call (for now)
  end

  def expect_selected_left_qing(qing)
    select = find('select[name*="\\[left_qing_id\\]"]')
    expect(page).to have_select(select[:name], selected: "#{qing.full_dotted_rank}. #{qing.code}")
  end

  def expect_selected_right_qing(qing)
    select = find('select[name*="\\[right_side_type\\]"]')
    expect(page).to have_select(select[:name], selected: "Another question ...")
    select = find('select[name*="\\[right_qing_id\\]"]')
    expect(page).to have_select(select[:name], selected: "#{qing.full_dotted_rank}. #{qing.code}")
  end

  def select_operator(op)
    find('select[name*="\\[op\\]"]').select(op)
  end

  def expect_selected_operator(op)
    select = find('select[name*="\\[op\\]"]')
    expect(page).to have_select(select[:name], selected: op)
  end

  def select_right_qing(code)
    find('select[name*="\\[right_side_type\\]"]').select("Another question ...")
    find('select[name*="\\[right_qing_id\\]"]').select(code)
  end

  def select_values(*values)
    selects = all('select[name*="\\[option_node_ids\\]"]')
    values.each_with_index do |value, i|
      selects[i].select(value)
    end
  end

  def expect_selected_values(*values)
    selects = all('select[name*="\\[option_node_ids\\]"]')
    expect(selects.size).to eq(values.size)
    selects.each_with_index do |select, i|
      expect(page).to have_select(select[:name], selected: values[i])
    end
  end

  def fill_in_value(value)
    find('input[name*="\\[value\\]"]').set(value)
  end

  def expect_filled_in_value(value)
    input = find('input[name*="\\[value\\]"]')
    expect(page).to have_field(input[:name], with: value)
  end

  def click_add_condition
    find("a", text: "Add Condition").click
  end

  def click_add_rule
    find("a", text: "Add Rule").click
  end

  def click_delete_link
    find(".fa-trash", match: :first).click
  end

  def click_remove_link
    find(".fa-close", match: :first).click
  end
end
