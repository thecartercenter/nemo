# frozen_string_literal: true

require "rails_helper"

feature "option set" do
  let(:user) { create(:user, role_name: "coordinator") }

  scenario "creating, showing, editing and exporting", js: true do
    login(user)
    click_link("Option Sets")

    # Fill in basic values
    click_link("Create New Option Set")
    fill_in("Name", with: "Foo")
    check("Is Multilevel?")

    click_link("Add Level")
    wait_modal_to_be_visible
    fill_in("English", with: "Typex")
    click_modal_save_button

    click_link("Add Level")
    wait_modal_to_be_visible
    fill_in("English", with: "Species")
    click_modal_save_button

    find("#option_levels a.action_link_edit", match: :first).click # Click first pencil link.
    wait_modal_to_be_visible
    fill_in("English", with: "Type") # Fix typo.
    click_modal_save_button

    # Go back to single level since dragging is hard here.
    2.times { find("#option_levels a.action_link_remove", match: :first).click }
    uncheck("Is Multilevel?")

    add_options(%w[Banana Apple])

    click_button("Save")

    # Should redirect back to index page.
    expect(page).to have_selector("td.name_col a", text: "Foo")

    # Test show mode (should have 'Apple' but no visible inputs or edit links).
    click_link("Foo")
    expect(page).to have_selector("#options-wrapper div", text: "Banana")
    expect(page).to have_selector("#options-wrapper div", text: "Apple")
    expect(page).not_to have_selector("form.option_set_form input[type=text]")
    expect(page).not_to have_selector("form.option_set_form a.action_link_edit")

    # Test edit mode (add another option)
    click_link("Edit Option Set")
    add_options(%w[Pear])
    click_button("Save")
    expect(page).to have_selector("td.options_col div", text: "Banana, Apple, Pear")

    # Test export page does not error out
    click_on "Foo"
    click_link("Edit Option Set")
    click_on "Export Option Set"
  end

  scenario "creating, showing, and editing options with values", js: true do
    login(user)
    click_link("Option Sets")

    click_link("Create New Option Set")
    fill_in("Name", with: "Foo")

    click_link("Add Option")
    wait_modal_to_be_visible
    fill_in("English", with: "Apple")
    fill_in("Value", with: "1")
    click_button("Save and Add Another")
    fill_in("English", with: "Banana")
    fill_in("Value", with: "2")
    click_button("Save and Close")
    click_button("Save")

    expect(page).to have_selector("td.name_col a", text: "Foo")

    click_link("Foo")
    expect(page).to have_selector("#options-wrapper div", text: "Apple (1)")
    expect(page).to have_selector("#options-wrapper div", text: "Banana (2)")

    click_link("Edit Option Set")
    find("#options a.action_link_edit", match: :first).click # Click first pencil link.
    wait_modal_to_be_visible

    fill_in("Value", with: "3")
    click_modal_save_button
    click_button("Save")

    click_link("Foo")
    expect(page).to have_selector("#options-wrapper div", text: "Apple (3)")
    expect(page).to have_selector("#options-wrapper div", text: "Banana (2)")
  end

  context "with standard set" do
    let!(:std_set) { create(:option_set, name: "Gold", is_standard: true, multilevel: true) }

    scenario "importing, editing, and showing", js: true do
      login(user)
      click_link("Option Sets")

      # Import
      click_link("Import Standard Option Sets")
      wait_modal_to_be_visible
      check("Gold")
      click_button("Import")
      wait_modal_to_hide
      wait_for_ajax
      expect(page).to have_selector("td.options_col div", text: "Animal, Plant")

      # Editing standard set (edit option level name and option name)
      find("a.action_link_edit", match: :first).click
      all("#option-levels-wrapper a.action_link_edit")[1].click
      wait_modal_to_be_visible
      fill_in("English", with: "Queendom")
      click_modal_save_button
      find("#options-wrapper ol ol a.action_link_edit", match: :first).click
      wait_modal_to_be_visible
      fill_in("English", with: "Kitty")
      click_modal_save_button
      click_button("Save")

      # Show standard set to verify save worked.
      click_link("Gold")
      expect(page).to have_selector("#options-wrapper div.inner", text: "Kitty")
    end
  end

  describe "deleting" do
    let(:set) { create(:option_set, multilevel: true) }

    scenario do
      login(user)
      visit(option_sets_path(mode: "m", mission_name: set.mission.compact_name, locale: "en"))
      find("a.action_link_destroy").click
      expect(page).to have_selector(".alert-success", text: "Option Set deleted successfully")
    end
  end

  def click_modal_save_button
    find(".modal-footer .btn-primary").click
    wait_modal_to_hide
  end

  def add_options(names)
    click_link("Add Option")
    names[0...-1].each do |name|
      fill_in("English", with: name)
      click_button("Save and Add Another")
    end
    fill_in("English", with: names.last)
    click_button("Save and Close")
  end
end
