# frozen_string_literal: true

require "rails_helper"

feature "forms flow", js: true do
  let!(:user) { create(:user) }
  let!(:form) do
    create(:form, name: "Foo", question_types: %w[integer multilevel_select_one select_one integer])
  end
  let(:forms_path) { "/en/m/#{form.mission.compact_name}/forms" }

  before do
    login(user)
  end

  describe "print from index" do
    scenario "should work and show tip the first time" do
      visit(forms_path)

      # First time printing should show tips.
      find("a.print-link").click
      expect(page).to have_css("h4", text: "Print Format Tips")
    end

    # Couldn't get this spec to work on headless chrome. Maybe it will work later.
    # context "with shown flag set" do
    #   scenario "should not show tip" do
    #     visit(forms_path)
    #     expect(page).to have_content('Form')
    #     date = Date.today.strftime("%Y-%m-%d")
    #     page.execute_script("window.localStorage.setItem('form_print_format_tips_shown', '#{date}')")
    #
    #     # Second time printing should not show tips.
    #     find('a.print-link').click
    #     expect(page).not_to have_css('h4', text: 'Print Format Tips')
    #   end
    # end
  end

  scenario "add nested groups to a form" do
    outer_name = "Outer Group"
    middle_name = "Middle Group"
    inner_name = "Inner Group"
    question_name = "[IntegerQ1] Integer Question Title 1"

    visit(edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
    create_group(outer_name)
    create_group(middle_name)
    create_group(inner_name)

    click_button("Save") # save form

    # Uses DOM manipulation to simulate moving items in the draggable list.
    # Capybara's drag_to doesn't work because the 'droppable' el isn't available
    # until the draggable item is clicked.

    nest_groups = <<~SCRIPT
      function itemLi(name) {
        return $('li .inner:contains(' + name + ')').parent();
      }
      function moveChildToParent(childName, newParentName) {
        var newParent = itemLi(newParentName);
        var newOl = $('<ol class=\"item-list ui-sortable\"></ol>');
        newParent.append(newOl);
        var item = itemLi(childName);
        item.detach().appendTo(newOl);
        ELMO.formItemsView.draggable.drop_happened(null, {item: item});
      }
      moveChildToParent('#{middle_name}', '#{outer_name}');
      setTimeout(function() {moveChildToParent('#{inner_name}', '#{middle_name}');}, 100)
      setTimeout(function() {moveChildToParent('#{question_name}', '#{inner_name}');}, 100)
    SCRIPT
    execute_script(nest_groups)
    click_button("Save")
    outer_css = ".draggable-list-wrapper ol li"
    middle_css = ".draggable-list-wrapper ol li ol li"
    inner_css = ".draggable-list-wrapper ol li ol li ol li"
    question_css = ".draggable-list-wrapper ol li ol li ol li ol li"
    within(".form-items") { expect(page).to have_css(outer_css, text: outer_name) }
    within(".form-items") { expect(page).to have_css(middle_css, text: middle_name) }
    within(".form-items") { expect(page).to have_css(inner_css, text: inner_name) }
    within(".form-items") { expect(page).to have_css(question_css, text: question_name) }
  end

  def create_group(name)
    click_link("Add Group")
    fill_in("Name (English)", with: name)
    check("qing_group_repeatable")
    within(".modal") { click_button("Save") }
  end
end
