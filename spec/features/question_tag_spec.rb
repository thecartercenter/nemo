require "rails_helper"

feature "question tags" do
  include_context "search"

  let!(:mission) { get_mission }
  let!(:question1) { create(:question, name: "How many cheeses?") }
  let!(:question2) { create(:question, name: "How many pies?") }
  let!(:question3) { create(:question, name: "How much juice?", is_standard: true, mission: nil) }
  let!(:form) { create(:form) }
  let!(:standard_form) { create(:form, is_standard: true, mission: nil) }
  let!(:questioning1) { create(:questioning, form: form, question: question1) }
  let!(:questioning2) { create(:questioning, form: form, question: question2) }
  let!(:questioning3) { create(:questioning, form: standard_form, question: question3) }
  let!(:tag1) { create(:tag, name: "dairy", mission: mission) }
  let!(:tag2) { create(:tag, name: "pastry", mission: mission) }
  let!(:tag3) { create(:tag, name: "beverage", mission: nil) }
  let!(:user) { create(:user, role_name: "coordinator", admin: true) }

  before do
    login(user)
  end

  scenario "question tag add/remove", :investigate, js: true do
    tag_add_remove_test(
      qtype: "question",
      edit_path: edit_question_path(question1, mode: "m", mission_name: mission.compact_name, locale: "en"),
      show_path: question_path(question1, mode: "m", mission_name: mission.compact_name, locale: "en"),
      admin_edit_path: edit_question_path(question3, mode: "admin", mission_name: nil, locale: "en"),
      admin_show_path: question_path(question3, mode: "admin", mission_name: nil, locale: "en"),
      input_id: "question_tag_ids",
      table_row_id: %{tr[id="question_#{question1.id}"]},
    )
  end

  scenario "questioning tag add/remove", :investigate, js: true do
    tag_add_remove_test(
      qtype: "questioning",
      edit_path: edit_questioning_path(questioning1, mode: "m", mission_name: mission.compact_name, locale: "en"),
      show_path: questioning_path(questioning1, mode: "m", mission_name: mission.compact_name, locale: "en"),
      admin_edit_path: edit_questioning_path(questioning3, mode: "admin", mission_name: nil, locale: "en"),
      admin_show_path: questioning_path(questioning3, mode: "admin", mission_name: nil, locale: "en"),
      input_id: "questioning_question_attributes_tag_ids",
      table_row_id: %{li.form-item[data-id="#{questioning1.id}"]},
    )
  end

  def tag_add_remove_test(options = {})
    visit options[:edit_path]
    expect(page).to have_content "Tags:"

    # Mission tags
    fill_in_token_input options[:input_id], with: "a", dont_pick: true
    expect(page).to have_content "dairy"
    expect(page).to have_content "pastry"

    fill_in_token_input options[:input_id], with: "da", dont_pick: true
    expect(page).to have_content "dairy"
    expect(page).not_to have_content "pastry"
    expect(page).to have_content "da [New tag]"

    # Apply tag
    find(".token-input-dropdown-elmo li", text: "dairy").click

    # Admin-mode tags should not appear here.
    fill_in_token_input options[:input_id], with: "b", dont_pick: true
    expect(page).not_to have_content "beverage"

    # Create a new tag
    fill_in_token_input options[:input_id], with: "snack", dont_pick: true
    find(".token-input-dropdown-elmo li", text: "snack").click

    # Add and then cancel a new tag
    fill_in_token_input options[:input_id], with: "drink", dont_pick: true
    find(".token-input-dropdown-elmo li", text: "drink").click

    within find("div#tag_ids li.token-input-token-elmo", text: "drink") do
      find("span.token-input-delete-token-elmo").click # "x" close button
    end
    expect(page).not_to have_content "drink"

    click_button "Save"

    # New tag should be in database
    expect(Tag.find_by_name("snack").mission_id).to eq mission.id
    # Canceled tag should not
    expect(Tag.pluck(:name)).not_to include("drink")

    # Tags show in questions row on index page
    # Check that index/form edit page has loaded
    expect(page).to have_selector "h1", text: (options[:qtype] == "question" ? "Questions" : /^Edit Form:/)
    within options[:table_row_id] do
      expect(page).to have_selector ".token-input-token-elmo", text: "dairy"
      expect(page).to have_selector ".token-input-token-elmo", text: "snack"
    end

    # On questions index page, also check that tags show at top
    if options[:qtype] == "question"
      within "div.all-tags" do
        expect(page).to have_selector "li", text: "dairy"
        expect(page).to have_selector "li", text: "snack"
      end
    end

    # Tags show on question(ing) show page
    visit options[:show_path]
    within "div#tag_ids" do
      expect(page).to have_selector "li", text: "dairy"
      expect(page).to have_selector "li", text: "snack"
      expect(page).not_to have_selector "li", text: "drink"
    end

    # Admin mode
    visit options[:admin_edit_path]

    fill_in_token_input options[:input_id], with: "v", dont_pick: true
    expect(page).to have_content "beverage"
    expect(page).not_to have_content "snack" # Non-standard tag
    find(".token-input-dropdown-elmo li", text: "beverage").click

    # Create a new tag
    fill_in_token_input options[:input_id], with: "food", dont_pick: true
    find(".token-input-dropdown-elmo li", text: /food/).click

    click_button "Save"

    # Tags show on question(ing) page
    visit options[:admin_show_path]
    within "div#tag_ids" do
      expect(page).to have_selector "li", text: "beverage"
    end

    expect(Tag.find_by_name("food").mission_id).to be_nil
  end

  scenario "clicking tag at top of question index page adds it to search", js: true do
    question1.tags = [tag1, tag2, tag3]
    visit "/en/m/#{mission.compact_name}/questions"

    # First search for something else
    search_for("cheese")
    expect(page).not_to have_content(question2.code)

    # Click tag
    first("li", text: "dairy").click
    expect(current_url).to include "search=cheese+tag%3Adairy"
    expect(page).to have_content(question1.code)
    expect(page).not_to have_content(question2.code)

    # Click another tag
    first("li", text: "pastry").click
    expect(current_url).to include "search=cheese+tag%3Apastry"
    expect(current_url).not_to include "beverage"
    expect(page).to have_content(question1.code)
    expect(page).not_to have_content(question2.code)

    # More complicated searches
    search_for("tag: (pastry |dairy )cheese")
    first("li", text: "pastry").click
    expect(current_url).to include "search=cheese+tag%3Apastry"

    search_for('cheese tag: "pastry"')
    first("li", text: "dairy").click
    expect(current_url).to include "search=cheese+tag%3Adairy"
  end
end
