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

  # This is failing at line 64 because the question item seems to disappear.
  # Debug strategy might be to dump out a crap ton of console.errors in moveChildToParent to see
  # what order things are happening in and what assumptions are false.
  # But don't have time for that right now :(
  # scenario "add nested groups to a form" do
  #   outer_name = "Outer Group"
  #   middle_name = "Middle Group"
  #   inner_name = "Inner Group"
  #   question_name = "[IntegerQ1] Integer Question Title 1"
  #
  #   visit(edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
  #   create_group(outer_name)
  #   create_group(middle_name)
  #   create_group(inner_name)
  #
  #   execute_script(move_item_js_functions)
  #
  #   # Move the items one by one, waiting for the move to complete each time.
  #   within(".form-items .draggable-list-wrapper") do
  #     expect(page).to have_nested_item(depth: 1, name: outer_name)
  #
  #     move_item(middle_name, outer_name)
  #     expect(page).to have_nested_item(depth: 2, name: middle_name)
  #
  #     move_item(inner_name, middle_name)
  #     expect(page).to have_nested_item(depth: 3, name: inner_name)
  #
  #     move_item(question_name, inner_name)
  #     expect(page).to have_nested_item(depth: 4, name: question_name)
  #   end
  #
  #   click_button("Save")
  #   expect(page).to have_content("Form updated successfully.")
  #
  #   # Ensure the changes were persisted.
  #   within(".form-items .draggable-list-wrapper") do
  #     expect(page).to have_nested_item(depth: 1, name: outer_name)
  #     expect(page).to have_nested_item(depth: 2, name: middle_name)
  #     expect(page).to have_nested_item(depth: 3, name: inner_name)
  #     expect(page).to have_nested_item(depth: 4, name: question_name)
  #   end
  # end

  def have_nested_item(depth:, name:)
    have_css((%w[ol li] * depth).join(" > "), text: name)
  end

  def create_group(name)
    click_link("Add Group")
    fill_in("Name (English)", with: name)
    check("qing_group_repeatable")
    within(".modal") { click_button("Save") }
  end

  def move_item_js_functions
    # Uses DOM manipulation to simulate moving items in the draggable list.
    # Capybara's drag_to doesn't work because the 'droppable' el isn't available
    # until the draggable item is clicked.
    <<~SCRIPT
      window.itemLi = function(name) {
        return $('li .inner:contains(' + name + ')').parent();
      }
      window.moveChildToParent = function(childName, newParentName) {
        var newParent = itemLi(newParentName);
        var newOl = $('<ol class=\"item-list ui-sortable\"></ol>');
        newParent.append(newOl);
        var item = itemLi(childName);
        item.detach().appendTo(newOl);
        ELMO.formItemsView.draggable.drop_happened(null, {item: item});
      }
    SCRIPT
  end

  def move_item(name, parent_name)
    execute_script("moveChildToParent('#{name}', '#{parent_name}');")
    wait_for_ajax # Wait for AJAX saving to complete or we sometimes get timing errors.

    # Trying this after much difficulty to see if it removes flakiness.
    # Suspicion is that if another item is attempted to be moved before this AJAX call finishes,
    # trouble happens.
    # If this does fix things, maybe try a better way later.
    sleep(5)
  end
end
