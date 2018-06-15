#Spec for GTRI 5-1 security requirement
require 'rails_helper'

describe "sanitizing responses" do
  let (:user) { create(:user) }

  it "removes script tags and inserts paragraph tags" do
    text = '<script> Foo \n \n Bar </script> '
    f = create(:form, question_types: %w(text))
    r = create(:response, form: f, answer_values: [text])

    login(user)
    get "/en/m/#{f.mission.compact_name}/responses/#{r.shortcode}"

    assert_response :success
    assert_select("div.qtype_text") do
      assert_select("p")
      assert_select("script", false)
    end
  end
end
