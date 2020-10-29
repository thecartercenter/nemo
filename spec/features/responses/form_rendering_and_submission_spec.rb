# frozen_string_literal: true

require "rails_helper"

feature "response form rendering and submission", js: true do
  include_context "response tree"
  include_context "file import"
  include_context "trumbowyg"

  let(:user) { create(:user) }

  let!(:form) do
    create(:form, :live,
      question_types: [
        %w[integer],
        "image",
        "multilevel_select_one",
        {
          repeating: {
            items: [
              %w[integer],
              {
                repeating: {
                  items: %w[integer]
                }
              },
              "image",
              "long_text"
            ]
          }
        },
        "decimal",
        "counter",
        "barcode",
        "select_one",
        "select_multiple",
        "datetime",
        "date",
        "time"
      ])
  end

  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name, form_id: form.id} }

  before do
    form.c[0].c[0].question.update!(minimum: 123)
    login(user)
  end

  describe "form rendering" do
    scenario "renders new form with hierarchical structure" do
      visit(new_response_path(params))

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
            {repeating: [[2, {repeating: [[3]]}]]},
            1.2,
            3,
            "barcode answer",
            "Dog",
            %w[Dog Cat],
            "Mar 12 #{Time.current.year} 18:32:44",
            "Oct 26 #{Time.current.year}",
            "03:08:23"
          ]
        )
      end

      scenario "renders edit form with hierarchical structure" do
        visit(edit_response_path(params.merge(id: response.shortcode)))

        expect_path([".cascading-selects select"])
        expect_path([
          ".answer-group-set", ".answer-group", ".answer-group-set", ".answer-group", ".answer input"
        ])
      end

      scenario "allows dynamic add/remove of nested repeat groups", js: true do
        visit(edit_response_path(params.merge(id: response.shortcode)))

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
    let(:image) { Rails.root.join("spec/fixtures/media/images/the_swing.jpg") }

    scenario "submitting response" do
      visit(new_response_path(params))

      select2(user.name, from: "response_user_id")
      fill_in_question([0, 0], with: "1")
      drop_in_dropzone(image, 0)
      fill_in_question([2], with: %w[Animal Dog])
      fill_in_question([3, 0, 0, 0], with: "4561")
      fill_in_question([3, 0, 1, 0, 0], with: "7891")
      drop_in_dropzone(image, 1)
      fill_in_question([3, 0, 3], with: "some text")

      # create new inner repeat
      all("a.add-repeat").first.click
      fill_in_question([3, 0, 1, 1, 0], with: "78911")

      # create new outer repeat
      # second outer group will not have an inner repeat
      all("a.add-repeat").last.click
      fill_in_question([3, 1, 0, 0], with: "4562")
      fill_in_question([3, 1, 1, 0, 0], with: "7892")
      drop_in_dropzone(image, 2)
      fill_in_question([3, 1, 3], with: "some other text")
      fill_in_question([4], with: "1.2")
      fill_in_question([5], with: "3")
      fill_in_question([6], with: "barcode answer")
      fill_in_question([7], with: "Dog")
      fill_in_question([8], with: %w[Dog Cat])
      fill_in_question([9], with: "Mar 12 #{Time.current.year} 18:32:44")
      fill_in_question([10], with: "Apr 4 #{Time.current.year}")
      fill_in_question([11], with: "03:08:23")
      click_button("Save")

      expect(page).to have_content("Response is invalid")
      expect_image([1], form.c[1].id)
      expect_value([3, 0, 0, 0], "4561")
      expect_value([3, 0, 1, 0, 0], "7891")
      expect_value([3, 0, 1, 1, 0], "78911")
      expect_image([3, 0, 2], form.c[3].c[2].id)
      expect_value([3, 0, 3], "some text")
      expect_value([3, 1, 0, 0], "4562")
      expect_value([3, 1, 1, 0, 0], "7892")
      expect_image([3, 1, 2], form.c[3].c[2].id)
      expect_value([3, 1, 3], "some other text")
      expect_value([4], "1.2")
      expect_value([5], "3")
      expect_value([6], "barcode answer")
      expect_value([7], "Dog")
      expect_value([8], %w[Dog Cat])
      expect_value([9], "Mar 12 #{Time.current.year} 18:32:44")
      expect_value([10], "Apr 4 #{Time.current.year}")
      expect_value([11], "03:08:23")

      # remove second inner repeat
      all("a.remove-repeat")[2].click

      fill_in_question([0, 0], with: "123")
      click_button("Save")

      expect(page).not_to(have_content("Response is invalid"))
      response = Response.last
      visit(edit_response_path(params.merge(id: response.shortcode)))

      expect_value([0, 0], "123")
      expect_image([1], form.c[1].id)
      expect_value([2, 0], "Animal")
      expect_value([2, 1], "Dog")
      expect_value([3, 0, 0, 0], "4561")
      expect_value([3, 0, 1, 0, 0], "7891")
      expect_image([3, 0, 2], form.c[3].c[2].id)
      expect_value([3, 0, 3], "some text")
      expect_value([3, 1, 0, 0], "4562")
      expect_value([3, 1, 1, 0, 0], "7892")
      expect_image([3, 1, 2], form.c[3].c[2].id)
      expect_value([3, 1, 3], "some other text")
      expect_value([4], "1.2")
      expect_value([5], "3")
      expect_value([6], "barcode answer")
      expect_value([7], "Dog")
      expect_value([8], %w[Dog Cat])
      expect_value([9], "Mar 12 #{Time.current.year} 18:32:44")
      expect_value([10], "Apr 4 #{Time.current.year}")
      expect_value([11], "03:08:23")
      # update a value
      fill_in_question([0, 0], with: "1234")

      # remove second outer repeat
      all("a.remove-repeat").last.click

      click_button("Save")
      expect(page).not_to have_content("Response is invalid")

      visit(edit_response_path(params.merge(id: response.shortcode)))

      expect_value([0, 0], "1234")
      expect_image([1], form.c[1].id)
      expect_value([2, 0], "Animal")
      expect_value([2, 1], "Dog")
      expect_value([3, 0, 0, 0], "4561")
      expect_value([3, 0, 1, 0, 0], "7891")
      expect_image([3, 0, 2], form.c[3].c[2].id)
      expect_value([3, 0, 3], "some text")
      expect_value([4], "1.2")
      expect_value([5], "3")
      expect_value([6], "barcode answer")
      expect_value([7], "Dog")
      expect_value([8], %w[Dog Cat])
      expect_value([9], "Mar 12 #{Time.current.year} 18:32:44")
      expect_value([10], "Apr 4 #{Time.current.year}")
      expect_value([11], "03:08:23")
    end

    context "with conditional logic" do
      before do
        form.c[2].update!(display_if: "all_met",
                          display_conditions_attributes: [{left_qing_id: form.c[0].c[0].id, op: "eq",
                                                           value: "123"}])
      end

      scenario "submitting response with irrelevant answers" do
        visit(new_response_path(params))
        select2(user.name, from: "response_user_id")
        fill_in_question([0, 0], with: "123") # Makes select boxes visible
        fill_in_question([2], with: %w[Animal Dog])
        fill_in_question([0, 0], with: "124") # Hides select boxes (making them irrelevant)
        click_button("Save")

        visit(edit_response_path(params.merge(id: Response.last.shortcode)))
        expect_value([0, 0], "124")

        expect_not_persisted(form.c[2].id) # Irrelevant answers not persisted
      end
    end

    # Normally we wouldn't feature test something as simple as validation but this form
    # has a lot going on with e.g. skip logic.
    context "with required question" do
      before do
        form.c[0].c[0].update!(required: true)
      end

      scenario do
        visit(new_response_path(params))
        select2(user.name, from: "response_user_id")
        click_button("Save")

        expect(page).to have_content("Response is invalid")
        expect(page).to have_content("Please enter a value")
        fill_in_question([0, 0], with: "124")
        click_button("Save")

        expect(page).to have_content("created successfully")
      end
    end
  end
end
