# frozen_string_literal: true

require "rails_helper"

describe OData::CacheListener do
  # Note: Since we're testing changes to these objects immediately after creation,
  # reload immediately to avoid tricky issues related to memory or caching.
  # Alternative solution that doesn't require `let!`: `create(:form).tap { |f| Form.find(f.id) }`
  let!(:user) { create(:user).reload }
  let!(:form) { create(:form, question_types: %w[text select_one]).reload }
  let!(:form2) { create(:form, question_types: ["text", %w[text text]]).reload }
  let!(:responses) do
    [
      create(:response, answer_values: %w[foo Cat], dirty_json: false, form: form, user: user).reload,
      create(:response, answer_values: %w[bar Dog], dirty_json: false, form: form, user: user).reload,
      create(:response, answer_values: ["foo", %w[bar baz]], dirty_json: false, form: form2).reload
    ]
  end
  let(:r1) { responses[0] }
  let(:r2) { responses[1] }
  let(:r3) { responses[2] }

  describe "update response" do
    it "marks dirty" do
      r1.update!(reviewed: true)
      expect_responses_dirty(true, false, false)
    end

    it "ignores irrelevant changes" do
      r1.update!(source: "foo")
      expect_responses_dirty(false, false, false)
    end
  end

  describe "update answer" do
    it "marks dirty (value)" do
      r1.c[0].update!(value: "bar")
      expect_responses_dirty(true, false, false)
    end

    it "marks dirty (latitude)" do
      r1.c[0].update!(latitude: 1.0)
      expect_responses_dirty(true, false, false)
    end
  end

  describe "update form" do
    it "marks multiple dirty" do
      r1.form.update!(name: "foo")
      expect_responses_dirty(true, true, false)
    end
  end

  describe "update user" do
    it "marks multiple dirty" do
      r1.user.update!(name: "foo")
      expect_responses_dirty(true, true, false)
    end
  end

  describe "update question" do
    it "marks multiple dirty" do
      r1.c[0].question.update!(code: "foo")
      expect_responses_dirty(true, true, false)
    end
  end

  describe "update questioning" do
    it "marks multiple dirty" do
      r1.c[0].questioning.update!(rank: 5)
      expect_responses_dirty(true, true, false)
    end
  end

  describe "update qing_group" do
    it "marks dirty (rank)" do
      r3.c[1].qing_group.update!(rank: 5)
      expect_responses_dirty(false, false, true)
    end

    it "marks dirty (repeatable)" do
      r3.c[1].qing_group.update!(repeatable: true)
      expect_responses_dirty(false, false, true)
    end

    it "marks dirty (group_name_translations)" do
      r3.c[1].qing_group.update!(group_name_en: "foo")
      expect_responses_dirty(false, false, true)
    end
  end

  # Reload all responses and expect certain ones to be dirty.
  def expect_responses_dirty(*values)
    responses.each(&:reload)
    expect(responses.pluck(:dirty_json)).to eq(values)
  end
end
