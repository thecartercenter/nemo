# frozen_string_literal: true

require "rails_helper"

feature "forms", js: true do
  INDENT = 40

  let!(:user) { create(:user) }
  let(:forms_path) { "/en/m/#{form.mission.compact_name}/forms" }
  let(:qings) { form.root_group.c }
  let!(:form) { create(:form, name: "Foo", question_types: question_types) }
  let(:edit_url) { edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name) }

  before do
    login(user)
  end

  context "with no groups" do
    let(:question_types) { %w[integer multilevel_select_one select_one integer] }

    scenario "adding nested groups" do
      outer_group = "Outer Group"
      inner_group = "Inner Group"
      question_name = form.questions.first.name

      visit(edit_url)
      create_group(outer_group)
      create_group(inner_group)

      within(".form-items .draggable-list-wrapper") do
        expect(page).to have_nested_item(path: [4], name: outer_group)
        expect(page).to have_nested_item(path: [5], name: inner_group)

        # nest inner group under outer group
        drag_item(from: [5], to: [5], indent: true)
        expect(page).to have_nested_item(path: [4, 0], name: inner_group)

        # nest first question under outer group
        drag_item(from: [0], to: [4, 0])
        expect(page).to have_nested_item(path: [3, 1], name: question_name)
      end

      # Edit a group
      click_form_item_action_icon([3, 0], :edit)
      expect(page).to have_css(".modal-title", text: "Edit Group")
      fill_in("Name (English)", with: "Inner Groupe")
      find(".modal-footer .btn-primary").click
      expect(page).to have_css("li", text: "Inner Groupe")
      click_button("Save")
      expect(page).to have_content("Form updated successfully.")

      # Ensure the changes were persisted.
      within(".form-items .draggable-list-wrapper") do
        expect(page).to have_nested_item(path: [3], name: outer_group)
        expect(page).to have_nested_item(path: [3, 0], name: "Inner Groupe")
        expect(page).to have_nested_item(path: [3, 1], name: question_name)
      end
    end

    scenario "dragging form elements" do
      old_first_question_name = form.c[0].name

      visit(edit_url)
      drag_item(from: [0], to: [3])
      drag_item(from: [0], to: [1], indent: true, release: false)
      expect(page).to have_content("The parent must be a group")
      release_item

      click_button("Save")
      expect(page).to have_content("Form updated successfully.")

      expect(form.reload.questions.last.name).to eq(old_first_question_name)
    end
  end

  context "with groups and questions" do
    let(:question_types) { ["integer", %w[integer]] }
    let(:q0_name) { form.c[0].code }
    let(:g1_name) { form.c[1].group_name }
    let(:q10_name) { form.c[1].c[0].code }

    scenario "deleting elements" do
      visit(edit_url)
      click_form_item_action_icon([1, 0], :delete)
      message = accept_confirm
      expect(message).to match("question '#{q10_name}'")
      wait_for_ajax # Need to wait or we get down into bottom part of the test before ajax completes.
      expect(page).not_to have_content(q10_name)

      click_form_item_action_icon([1], :delete)
      message = accept_confirm
      expect(message).to match("group '#{g1_name}'")
      wait_for_ajax
      expect(page).not_to have_content(g1_name)

      # Leave page and return to ensure correctly persisted.
      visit(forms_path)
      click_link(form.name)
      expect(page).to have_content(q0_name)
      expect(page).not_to have_content(q10_name)
      expect(page).not_to have_content(g1_name)
    end
  end

  context "with conditions" do
    let(:question_types) { %w[integer multilevel_select_one select_one integer] }

    before do
      qings[1].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing_id: qings[0].id, op: "eq", value: 123}
        ]
      )
    end

    # For some inexplicable reason, a weird span element is required in
    # app/views/forms/form.html.erb for this spec to pass. See that file for more details.
    scenario "dragging form elements" do
      visit(edit_url)

      # try dragging conditional item above the question on which it depends
      drag_item(from: [1], to: [0], release: false)
      expect(page).to have_content("This position would invalidate a condition")
      release_item

      # try dragging dependent item below conditional question
      drag_item(from: [0], to: [2], release: false)
      expect(page).to have_content("This position would invalidate a condition")
      release_item

      # try dragging conditional item further down the list
      drag_item(from: [1], to: [2], release: false)
      expect(page).not_to have_content("This position would invalidate a condition")
      release_item

      click_button("Save")
      expect(page).to have_content("Form updated successfully.")
    end
  end

  context "with groups and conditions" do
    let(:question_types) { ["integer", %w[integer], %w[integer]] }

    before do
      qings[1].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing: form.c[0], op: "gt", value: "5"}
        ]
      )
      qings[2].update!(
        display_if: "all_met",
        display_conditions_attributes: [
          {left_qing: form.c[0], op: "gt", value: "6"}
        ]
      )
    end

    scenario "editing several group conditions successively" do
      visit(edit_url)
      click_form_item_action_icon([1], :edit)
      within(".modal") do
        find(".condition-value input").set("15")
        find(".btn-primary").click
      end

      click_form_item_action_icon([1], :edit)
      within(".modal") do
        expect(find(".condition-value input").value).to eq("15")
        find(".btn-primary").click
      end

      click_form_item_action_icon([2], :edit)
      within(".modal") do
        expect(find(".condition-value input").value).to eq("6")
        find(".condition-value input").set("16")
        find(".btn-primary").click
      end

      click_form_item_action_icon([2], :edit)
      within(".modal") do
        expect(find(".condition-value input").value).to eq("16")
      end
    end
  end

  def create_group(name)
    click_link("Add Group")
    fill_in("Name (English)", with: name)
    check("qing_group_repeatable")
    within(".modal") { click_button("Save") }
  end

  def form_item_selector(path, inner: false)
    selector = [".draggable-list-wrapper"]

    path.each do |index|
      selector << "> ol.item-list"
      # nth-child is 1-indexed
      selector << "> li.form-item:nth-child(#{index + 1})"
    end

    selector.join(" ") << (inner ? "> div.inner" : "")
  end

  def form_item(path, inner: false)
    find(form_item_selector(path, inner: inner))
  end

  def click_form_item_action_icon(path, action)
    icon_class = case action
                 when :delete then "fa-trash-o"
                 when :edit then "fa-pencil"
                 end
    form_item(path, inner: true).find(".#{icon_class}").click
  end

  def release_item
    page.driver.browser.action.release.perform
  end

  def drag_item(from:, to:, release: true, indent: false)
    from_el = form_item(from)
    to_el = form_item(to)

    page.driver.browser.action.click_and_hold(from_el.native).perform
    page.driver.browser.action.move_to(to_el.native).perform
    page.driver.browser.action.move_by(indent ? INDENT : 0, 10).perform

    release_item if release
  end

  def have_nested_item(path:, name:)
    selector = form_item_selector(path)
    have_css(selector, text: name)
  end
end
