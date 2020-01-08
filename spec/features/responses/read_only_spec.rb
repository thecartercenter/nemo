# frozen_string_literal: true

require "rails_helper"

feature "response form read only mode", js: true do
  include_context "response tree"

  let(:user) { create(:user) }
  let(:form) { create(:form, :live, question_types: question_types) }
  let(:response) do
    create(:response, form: form, mission: get_mission, user: user, answer_values: answer_values)
  end
  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(user) }

  context "with simple form" do
    let(:question_types) { %w[text integer] }
    let(:answer_values) { %w[foo 123] }

    it "renders" do
      visit response_path(response, params)

      expect(page).to have_css("a", text: user.name)
      expect_read_only_value([0], "foo")
      expect_read_only_value([1], "123")
    end
  end

  context "with no questions" do
    let(:question_types) { %w[] }
    let(:answer_values) { %w[] }

    it "renders" do
      visit response_path(response, params)
      expect(page).to have_css("a", text: user.name)
    end
  end

  context "with hierarchical structure" do
    let(:question_types) do
      [
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
        }
      ]
    end
    let(:answer_values) do
      [
        [123],
        create(:media_image),
        %w[Plant Oak],
        {
          repeating: [
            [
              [234],
              {repeating: [[456]]},
              create(:media_image),
              "testing <script>Hi</script>"
            ]
          ]
        }
      ]
    end

    it "renders" do
      visit response_path(response, params)

      expect_read_only_value([0, 0], "123")
      expect_image([1], form.root_group.c[1].id)
      expect_read_only_value([2], "Plant")
      expect_read_only_value([2], "Oak")
      expect_read_only_value([3, 0, 0], "234")
      expect_read_only_value([3, 0, 1, 0], "456")
      expect_image([3, 0, 2], form.root_group.c[3].c[2].id)
      expect_read_only_value([3, 0, 3], "testing Hi")
    end
  end
end
