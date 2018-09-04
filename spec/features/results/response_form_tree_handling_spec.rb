# frozen_string_literal: true

require "rails_helper"

feature "response form tree handling", js: true do
  include_context "dropzone"

  let(:user) { create(:user) }

  let!(:form) do
    create(:form,
      question_types: [
        %w[integer],
        "image",
        "multilevel_select_one",
        {
          repeating: {
            items: [
              %w[integer],
              repeating: {
                items: %w[integer]
              }
            ]
          }
        }
      ])
  end

  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

  before do
    question = form.root_group.c[0].c[0].question
    question.minimum = 123
    question.save!

    form.publish!
  end

  before(:each) { login(user) }

  describe "form rendering" do
    scenario "renders new form with hierarchical structure" do
      visit new_hierarchical_response_path(params)

      expect_path([".cascading-selects select"])
      expect_path([
        ".answer-group-set", ".answer-group", ".answer-group-set", ".answer-group", ".answer input"
      ])
    end

    context "with response" do
      let!(:response) do
        create(
          :response,
          form: form,
          mission: get_mission,
          user: user,
          answer_values: [
            [123],
            create(:media_image),
            %w[Plant Oak],
            {repeating: [[2, {repeating: [[3]]}]]}
          ]
        )
      end

      scenario "renders edit form with hierarchical structure" do
        visit edit_hierarchical_response_path(params.merge(id: response.shortcode))

        expect_path([".cascading-selects select"])
        expect_path([
          ".answer-group-set", ".answer-group", ".answer-group-set", ".answer-group", ".answer input"
        ])
      end

      scenario "allows dynamic add/remove of nested repeat groups", js: true do
        visit edit_hierarchical_response_path(params.merge(id: response.shortcode))

        # 1 "Add" and "Remove" button per repeat group
        expect(page).to have_css("a.add-repeat", count: 2)
        expect(page).to have_css("a.remove-repeat", count: 2)

        # Add new inner repeat
        all(:css, "a.add-repeat").first.click

        # New "Remove" button present for the inner repeat
        expect(page).to have_css("a.remove-repeat", count: 3)

        # Add new outer repeat
        all(:css, "a.add-repeat").last.click

        # 1 new "Add" for the inner repeat, 2 new "Removes" (1 innner, 1 outer)
        expect(page).to have_css("a.add-repeat", count: 3)
        expect(page).to have_css("a.remove-repeat", count: 5)

        # Remove outer repeat (should be the 4th x link on the page)
        all(:css, "a.remove-repeat")[3].click

        expect(page).to have_css("a.add-repeat", count: 2)
        expect(page).to have_css("a.remove-repeat", count: 3)
      end
    end
  end

  describe "form submission" do
    scenario "submitting response" do
      visit new_hierarchical_response_path(params)

      select2(user.name, from: "response_user_id")
      fill_in_question([0, 0], with: "1")
      drop_in_dropzone(Rails.root.join("spec", "fixtures", "media", "images", "the_swing.jpg"))
      select("Animal")
      select("Dog")
      fill_in_question([3, 0, 0, 0], with: "4561")
      fill_in_question([3, 0, 1, 0, 0], with: "7891")
      all("a.add-repeat").last.click
      fill_in_question([3, 1, 0, 0], with: "4562")
      fill_in_question([3, 1, 1, 0, 0], with: "7892")
      click_button("Save")

      expect(page).to have_content("Response is invalid")
      expect_value([3, 0, 0, 0], "4561")
      expect_value([3, 0, 1, 0, 0], "7891")
      expect_value([3, 1, 0, 0], "4562")
      expect_value([3, 1, 1, 0, 0], "7892")

      fill_in_question([0, 0], with: "123")
      click_button("Save")

      expect(page).to_not have_content("Response is invalid")

      response = Response.last
      visit edit_hierarchical_response_path(params.merge(id: response.shortcode))

      expect_value([0, 0], "123")
      expect(page).to have_selector("[data-qtype-name=image] .media-thumbnail img")
      expect_value([2, 0], "Animal")
      expect_value([2, 1], "Dog")
      expect_value([3, 0, 0, 0], "4561")
      expect_value([3, 0, 1, 0, 0], "7891")
      expect_value([3, 1, 0, 0], "4562")
      expect_value([3, 1, 1, 0, 0], "7892")
    end

    context "with conditional logic" do
      before do
        ref_qing = form.root_group.c[0].c[0]

        questioning = form.root_group.c[2]
        questioning.display_if = "all_met"
        questioning.display_conditions_attributes = [
          {ref_qing_id: ref_qing.id, op: "eq", value: "123"}
        ]
        questioning.save!
      end

      scenario "submitting response" do
        visit new_hierarchical_response_path(params)

        select2(user.name, from: "response_user_id")

        # makes select boxes visible
        fill_in_question([0, 0], with: "123")

        select("Animal")
        select("Dog")

        # hides select boxes, they are now irrelevant
        fill_in_question([0, 0], with: "124")

        click_button("Save")

        response = Response.last
        visit edit_hierarchical_response_path(params.merge(id: response.shortcode))

        expect_value([0, 0], "124")

        # select answers not persisted
        expect_not_persisted(form.root_group.c[2].id)
      end
    end
  end

  def path_selector(indices, suffix = "value")
    path = ["children"] + indices.zip(["children"] * (indices.length - 1)).flatten.compact
    "response_root_#{path.join('_')}_#{suffix}"
  end

  def fill_in_question(path, opts)
    fill_in(path_selector(path, "value"), opts)
  end

  def expect_path(path, options = {})
    selector = path.join(" .children ")
    expect(page).to have_selector(selector, options)
  end

  def expect_value(path, expected_value)
    actual_value =
      case qing(path).qtype_name
      when "select_one"
        el = page.find("#" + path_selector(path, "option_node_id"))
        OptionNode.find(el.value).option_name if el.value
      else
        page.find("#" + path_selector(path, "value")).value
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
end
