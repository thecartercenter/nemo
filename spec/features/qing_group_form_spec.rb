require "rails_helper"

feature "adding and editing qing group on form", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:form, name: "Foo",
    question_types: %w(integer multilevel_select_one select_one integer)) }

  before do
    get_mission.setting.update_attribute(:preferred_locales_str, "en,fr")
    login(user)
  end

  scenario "add a new group to a form" do
    visit(edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))

    click_link("Add Group")
    fill_in("Name (English):", with: "Foo Group")
    fill_in("Hint (English):", with: "Bar Hint")
    fill_in("Name (Français):", with: "Fou Groupe")
    fill_in("Hint (Français):", with: "Barre Hinte")

    # Test display conditions when creating new group
    select("Display this group if all of these conditions are met", from: "qing_group_display_logic")
    find(".add-condition")
    find('select[name$="[ref_qing_id]"]').select(form.c[0].code)
    find('select[name$="[op]"]').select("= equals")
    find('input[name$="[value]"]').set("3")

    expect(page).not_to have_content("Item Name (English)")
    check("qing_group_repeatable")
    fill_in("Item Name (English):", with: "Test Name")
    fill_in("Item Name (Français):", with: "Nom d'essaie")
    uncheck("qing_group_one_screen")
    within(".modal") { click_button("Save") }

    within(".form-items") { expect(page).to have_content("Foo Group") }
    all(".form-items .action_link.edit")[-1].click
    expect(page).to have_field("qing_group_group_name_en", with: "Foo Group")
    expect(page).to have_field("qing_group_group_name_fr", with: "Fou Groupe")
    expect(page).to have_field("qing_group_group_hint_en", with: "Bar Hint")
    expect(page).to have_field("qing_group_group_hint_fr", with: "Barre Hinte")
    expect(page).to have_field("qing_group_repeatable", checked: true)
    expect(page).to have_field("qing_group_one_screen", checked: false)
    expect(page).to have_field("qing_group_group_item_name_en", with: "Test Name")
    expect(page).to have_field("qing_group_group_item_name_fr", with: "Nom d'essaie")

    # Test display condition saved. Detailed test is in display_conditions_form_spec
    expect(page).to have_select("qing_group_display_logic",
      selected: "Display this group if all of these conditions are met")

    fill_in("Name (English):", with: "New Group Name")
    within(".modal") { click_button("Save") }
    within(".form-items") { expect(page).to have_content("New Group Name") }
  end

end
