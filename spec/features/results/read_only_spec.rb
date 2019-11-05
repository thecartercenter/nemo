# frozen_string_literal: true

require "rails_helper"

feature "response form read only mode", js: true do
  include_context "response tree"

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
        }
      ])
  end

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
    )
  end

  let(:params) { {locale: "en", mode: "m", mission_name: get_mission.compact_name} }

  before { login(user) }

  scenario "renders response with hierarchical structure" do
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
