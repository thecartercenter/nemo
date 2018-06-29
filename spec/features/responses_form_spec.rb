require "rails_helper"

feature "responses form", js: true do
  let(:user) { create(:user) }
  let!(:form) { create(:form, :published) }
  let(:form_questionings) { form.questionings }
  let(:response) { Response.first }
  let(:response_link) { response.decorate.shortcode.to_s }
  let(:response_path_params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

  describe "general", database_cleaner: :all, order: :defined do
    let!(:questionings) do
      {
        select_one: create_questioning("select_one", form),
        multilevel_select_one: create_questioning("multilevel_select_one", form),
        select_multiple: create_questioning("select_multiple", form),
        integer: create_questioning("integer", form),
        decimal: create_questioning("decimal", form),
        location: create_questioning("location", form),
        text: create_questioning("text", form),
        long_text: create_questioning("long_text", form),
        datetime: create_questioning("datetime", form),
        date: create_questioning("date", form),
        time: create_questioning("time", form)
      }
    end
    let(:questioning_answers) do
      {
        select_one: "Dog",
        multilevel_select_one: %w(Plant Oak),
        select_multiple: "Cat",
        integer: "10",
        decimal: "10.2",
        location: "42.277976 -83.817573",
        text: "Foo",
        long_text: "Foo Bar Baz",
        datetime: "Mar 12 #{Time.now.year} 18:32:44",
        date: "Oct 26 #{Time.now.year}",
        time: "03:08:23"
      }
    end
    let(:reviewer) { create(:user) }

    # TODO: find a better way to share this data for show/edit
    before do
      login(user)
      visit new_response_path(response_path_params)
      select2(user.name, from: "response_user_id")

      control_for(questionings[:select_one]).select("Dog")
      control_for(questionings[:multilevel_select_one], subfield: 1).select("Plant")
      control_for(questionings[:multilevel_select_one], subfield: 2).select("Oak")
      control_for(questionings[:select_multiple]).check("Cat")

      fill_in(control_id_for(questionings[:integer]), with: "10")
      fill_in(control_id_for(questionings[:decimal]), with: "10.2")
      fill_in(control_id_for(questionings[:location]), with: "42.277976 -83.817573")
      fill_in(control_id_for(questionings[:text]), with: "Foo")
      fill_in_ckeditor(control_id_for(questionings[:long_text], visible: false), with: "Foo Bar\nBaz")

      control_for(questionings[:datetime], subfield: :year).select(Time.now.year)
      control_for(questionings[:datetime], subfield: :month).select("Mar")
      control_for(questionings[:datetime], subfield: :day).select("12")
      control_for(questionings[:datetime], subfield: :hour).select("18")
      control_for(questionings[:datetime], subfield: :minute).select("32")
      control_for(questionings[:datetime], subfield: :second).select("44")

      control_for(questionings[:date], subfield: :year).select(Time.now.year)
      control_for(questionings[:date], subfield: :month).select("Oct")
      control_for(questionings[:date], subfield: :day).select("26")

      control_for(questionings[:time], subfield: :hour).select("03")
      control_for(questionings[:time], subfield: :minute).select("08")
      control_for(questionings[:time], subfield: :second).select("23")

      click_button("Save")
    end

    scenario "submit response" do
      expect(page).to have_selector("h1", text: "Response")
    end

    scenario "show response" do
      # Check answers saved
      click_link(response_link)

      questioning_answers.each do |qing, answer|
        expect_answer(questioning: qing, answer: answer)
      end
    end

    scenario "edit response", js: true do
      click_link(response_link)
      click_link("Edit Response")
      select2(reviewer.name, from: "response_reviewer_id")

      control_for(questionings[:multilevel_select_one], subfield: 1).select("Animal")
      control_for(questionings[:multilevel_select_one], subfield: 2).select("Cat")

      control_for(questionings[:select_multiple]).uncheck("Cat")
      control_for(questionings[:select_multiple]).check("Dog")

      click_button("Save and Mark as Reviewed")

      click_link(response_link)

      expect(page).to have_selector("#reviewed", text: "Yes")

      modified_answers = questioning_answers.merge({multilevel_select_one: %w(Animal Cat), select_multiple: "Dog"})
      modified_answers.each do |qing, answer|
        expect_answer(questioning: qing, answer: answer)
      end
    end

    scenario "delete response" do
      click_link(response_link)

      accept_confirm do
        click_link("Delete Response")
      end

      expect(page).to have_selector(".alert-success", text: "deleted")
    end
  end

  describe "hidden questions" do
    let!(:questionings) do
      {
        text: create_questioning("text", form),
        text_hidden: create(:questioning,
          question: create(:question, qtype_name: "text"), form: form, hidden: true, required: true)
      }
    end

    scenario "should be properly ignored" do
      login(user)
      visit new_response_path(response_path_params)
      select2(user.name, from: "response_user_id")

      expect(page).not_to have_selector("div.form-field#qing_#{questionings[:text_hidden].id}")
      fill_in(control_id_for(questionings[:text]), with: "Foo")
      click_button("Save")

      # Ensure response saved properly.
      click_link(response_link)
      expect(page).not_to have_selector("[data-qing-id=\"#{questionings[:text_hidden].id}\"]")
      expect(page).to have_selector("[data-qing-id=\"#{questionings[:text].id}\"] .ro-val", text: "Foo")
    end
  end

  describe "integer constraints" do
    let!(:questionings) do
      {
        integer: create(:questioning, form: form,
                                      question: create(:question, qtype_name: "integer", minimum: 10))
      }
    end

    scenario "should be enforced if appropriate" do
      login(user)
      visit new_response_path(response_path_params)
      select2(user.name, from: "response_user_id")

      fill_in(control_id_for(questionings[:integer]), with: "11")
      click_button("Save")
      expect(page).to have_content "Response created successfully"

      click_link(response_link)
      click_link("Edit Response")

      fill_in(control_id_for(questionings[:integer]), with: "")
      click_button("Save")
      expect(page).to have_content "Response updated successfully"
    end
  end

  describe "location answers" do
    let!(:questionings) { {location: create_questioning("location", form)} }

    scenario "should be handled properly" do
      login(user)
      visit new_response_path(response_path_params)
      select2(user.name, from: "response_user_id")

      fill_in(control_id_for(questionings[:location]), with: "12.3 45.6")
      click_button("Save")
      click_link(response_link)
      expect(page).to have_content "12.300000 45.600000"

      click_link("Edit Response")
      fill_in(control_id_for(questionings[:location]), with: "12.3 45.6 789.1 23")
      click_button("Save")
      click_link(response_link)
      expect(page).to have_content "12.300000 45.600000 789.100 23.000"
    end
  end

  describe "reviewer notes" do
    let(:enumerator) { create(:user, role_name: :enumerator) }
    let(:form) { create(:form, :published, question_types: %w(integer)) }
    let(:response) { create(:response, :is_reviewed, form: form, answer_values: [0], user: enumerator) }
    let(:notes) { response.reviewer_notes }

    scenario "should not be visible to normal users" do
      login(enumerator)
      visit(response_path(response, locale: "en", mode: "m", mission_name: get_mission.compact_name))
      expect(page).not_to have_content(notes)
    end

    scenario "should be visible to admin" do
      login(create(:user, admin: true))
      visit(response_path(response, locale: "en", mode: "m", mission_name: get_mission.compact_name))
      expect(page).to have_content(notes)
    end

    scenario "should be visible to staffer" do
      login(create(:user, role_name: :staffer))
      visit(response_path(response, locale: "en", mode: "m", mission_name: get_mission.compact_name))
      expect(page).to have_content(notes)
    end
  end

  describe "repeat groups" do
    let(:qing_group) { create(:qing_group, form: form, repeatable: true) }
    let!(:questionings) do
      {
        select_one: create_questioning("select_one", form),
        group_integer: create_questioning("integer", form, parent: qing_group),
        group_text: create_questioning("text", form, parent: qing_group),
        group_multilevel: create_questioning("multilevel_select_one", form, parent: qing_group),
        text: create_questioning("text", form)
      }
    end

    scenario "should let you add two instances" do
      login(user)
      visit new_response_path(response_path_params)
      select2(user.name, from: "response_user_id")

      control_for(questionings[:select_one]).select("Cat")
      find("a.add-instance").click
      fill_in control_id_for(questionings[:group_integer], instance_num: 2), with: 10
    end
  end

  def control_for(questioning, subfield: nil, visible: true, instance_num: nil)
    instance_prefix = "[data-inst-num='#{instance_num}']" if instance_num
    prefix = "div[data-qing-id='#{questioning.id}']#{instance_prefix} .control"

    if questioning.qtype_name == "select_multiple"
      find("#{prefix} .widget", visible: visible)
    elsif questioning.temporal?
      find("#{prefix} select[id$='#{temporal_mapping[subfield]}']", visible: visible)
    elsif questioning.multilevel?
      find("#{prefix} .level:nth-child(#{subfield}) .form-control", visible: visible)
    else
      find("#{prefix} .form-control", visible: visible)
    end
  end

  def control_id_for(questioning, subfield: nil, visible: true, instance_num: nil)
    control_for(questioning, subfield: subfield, visible: visible, instance_num: instance_num)["id"]
  end

  def temporal_mapping
    {year: "1i", month: "2i", day: "3i", hour: "4i", minute: "5i", second: "6i"}
  end

  def expect_answer(questioning: nil, answer: nil)
    qing = questionings[questioning]
    selector_class = qing.multilevel? ? "option-name" : "ro-val"
    Array.wrap(answer).each do |a|
      expect(page).to have_selector("[data-qing-id=\"#{qing.id}\"] .#{selector_class}", text: /^#{Regexp.escape(a)}$/)
    end
  end
end
