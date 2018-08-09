# frozen_string_literal: true

require "rails_helper"

feature "response form tree handling", js: true do
  let(:user) { create(:user) }

  describe "form rendering", database_cleaner: :all do
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

    before { form.publish! }

    let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

    before(:each) { login(user) }

    scenario "renders new form with hierarchical structure" do
      visit new_hierarchical_response_path(params)

      expect_path([".answer-group", ".answer-group", ".answer input"])
      expect_path([".answer-group", ".answer input"])
      expect_path([".answer-group", ".cascading-selects select"])
      expect_path([
        ".answer-group", ".answer-group-set",
        ".answer-group", ".answer-group", ".answer input"
      ])
      expect_path([
        ".answer-group", ".answer-group-set",
        ".answer-group", ".answer-group-set", ".answer-group", ".answer input"
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
            [1],
            create(:media_image),
            %w[Plant Oak],
            {repeating: [[2, {repeating: [[3]]}]]}
          ]
        )
      end

      scenario "renders edit form with hierarchical structure" do
        visit edit_hierarchical_response_path(params.merge(id: response.shortcode))

        expect_path([".answer-group", ".answer-group", ".answer input"])
        expect_path([".answer-group", ".answer input"])
        expect_path([".answer-group", ".cascading-selects select"])
        expect_path([
          ".answer-group", ".answer-group-set",
          ".answer-group", ".answer-group", ".answer input"
        ])
        expect_path([
          ".answer-group", ".answer-group-set",
          ".answer-group", ".answer-group-set", ".answer-group", ".answer input"
        ])
      end

      scenario "allows dynamic add/remove of nested repeat groups", js: true do
        visit edit_hierarchical_response_path(params.merge(id: response.shortcode))

        # 1 "Add" and "Remove" button per repeat group
        expect(page).to have_content("Add", count: 2)
        expect(page).to have_content("Remove", count: 2)

        # Add new inner repeat
        all(:link, "Add").first.click

        # New "Remove" button present for the inner repeat
        expect(page).to have_content("Remove", count: 3)

        # Add new outer repeat
        all(:link, "Add").last.click

        # 1 new "Add" for the inner repeat, 2 new "Removes" (1 innner, 1 outer)
        expect(page).to have_content("Add", count: 3)
        expect(page).to have_content("Remove", count: 5)

        # Remove outer repeat
        all(:link, "Remove").last.click

        expect(page).to have_content("Add", count: 2)
        expect(page).to have_content("Remove", count: 3)
      end

      scenario "renders show page with hierarchical structure" do
        visit hierarchical_response_path(params.merge(id: response.shortcode))

        # These nodes are not visible since the answers have no value

        expect_path([".answer-group", ".answer-group", ".answer .ro-val"], visible: false)
        expect_path([".answer-group", ".answer .ro-val"], visible: false)
        expect_path([".answer-group", ".ro-val .cascading-selects"], visible: false)
        expect_path([
          ".answer-group", ".answer-group-set",
          ".answer-group", ".answer-group", ".answer .ro-val"
        ], visible: false)
        expect_path([
          ".answer-group", ".answer-group-set",
          ".answer-group", ".answer-group-set", ".answer-group", ".answer .ro-val"
        ], visible: false)
      end
    end
  end

  def expect_path(path, options = {})
    selector = path.join(" .children ")
    expect(page).to have_selector(selector, options)
  end
end
