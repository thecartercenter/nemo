require "spec_helper"

feature "conditions flow", js: true do
  let!(:user) { create(:user) }
  let!(:form) { create(:form, name: "Foo") }
  let!(:questionings) do
    {
      multilevel_select_one: create_questioning("multilevel_select_one", form),
      integer: create_questioning("integer", form),
      text: create_questioning("text", form)
    }
  end
  let(:question_code) { questionings[:multilevel_select_one].code }
  let(:last_questioning) { Questioning.order(:created_at).last }

  before do
    login(user)
    visit(edit_form_path(form, locale: "en", mode: "m", mission_name: get_mission.compact_name))
    expect(page).to have_content("Edit Form")
  end

  scenario "add and update condition to existing question" do
    all("a.action_link.edit")[1].click
    select_question_and_wait_to_populate_other_selects(1, question_code)
    select("is equal to", from: "Comparison")
    select("Animal", from: "Kingdom")
    click_button("Save")

    # View the questioning and ensure the condition is shown correctly.
    visit("/en/m/#{form.mission.compact_name}/questionings/#{questionings[:integer].id}")
    expect(page).to have_content("Question #1 #{question_code}
      Kingdom is equal to \"Animal\"")

    # Update the condition to have a full option path.
    visit("/en/m/#{form.mission.compact_name}/forms/#{form.id}/edit")
    all("a.action_link.edit")[1].click
    select("Dog", from: "Species")
    click_button("Save")

    # View and test again.
    visit("/en/m/#{form.mission.compact_name}/questionings/#{questionings[:integer].id}")
    expect(page).to have_content("Question #1 #{question_code}
      Species is equal to \"Dog\"")

    # This is a temporary model-level check until the form includes this field explictly nd we can
    # check it in the UI.
    expect(form.c[1].reload.display_if).to eq "all_met"
  end

  scenario "add a new question with a condition" do
    click_link("Add Questions")
    fill_in("Code", with: "NewQ")
    select("Text", from: "Type")
    fill_in("Title (English)", with: "New Question")
    select_question_and_wait_to_populate_other_selects(1, question_code)
    select("is equal to", from: "Comparison")
    select("Plant", from: "Kingdom")
    select("Oak", from: "Species")
    click_button("Save")

    visit("/en/m/#{form.mission.compact_name}/questionings/#{last_questioning.id}")
    expect(page).to have_content("Question #1 #{question_code}
      Species is equal to \"Oak\"")
  end

  context "with condition on integer question" do
    let(:question_code) { questionings[:integer].code }

    scenario "add a less than condition" do
      all("a.action_link.edit")[2].click
      select_question_and_wait_to_populate_other_selects(2, question_code)
      select("is less than", from: "Comparison")
      fill_in("Value", with: "5")
      click_button("Save")

      # View the questioning and ensure the condition is shown correctly.
      visit("/en/m/#{form.mission.compact_name}/questionings/#{questionings[:text].id}")
      expect(page).to have_content("Question #2 #{question_code} is less than 5")
    end
  end


  def select_question_and_wait_to_populate_other_selects(counter, question_code)
    select(question_label(counter, question_code), from: "Question")
    wait_for_ajax
  end

  def question_label(counter, question_code)
    "#{counter}. #{question_code}"
  end
end
