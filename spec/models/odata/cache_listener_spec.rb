# frozen_string_literal: true

require "rails_helper"

describe OData::CacheListener do
  # Since we're testing changes to these objects immediately after creation,
  # reload to avoid tricky issues related to memory or caching.
  # An alternative solution is: `create(:form).tap { |f| Form.find(f.id) }`
  let!(:user) { create(:user).reload }
  let!(:form) { create(:form, question_types: %w[text select_one]).reload }
  let!(:form2) { create(:form, question_types: ["text", %w[text text]]).reload }
  let!(:response) do
    create(:response, answer_values: %w[foo Cat], dirty_json: false, form: form, user: user).reload
  end
  let!(:response2) do
    create(:response, answer_values: %w[bar Dog], dirty_json: false, form: form, user: user).reload
  end
  let!(:response3) do
    create(:response, answer_values: ["foo", %w[bar baz]], dirty_json: false, form: form2).reload
  end

  describe "update response" do
    it "marks dirty" do
      response.update!(reviewed: true)
      expect_dirty(response)
    end

    it "ignores irrelevant changes" do
      response.update!(source: "foo")
      expect_clean(response)
    end
  end

  describe "update answer" do
    it "marks dirty (value)" do
      response.c[0].update!(value: "bar")
      expect_dirty(response)
    end

    it "marks dirty (latitude)" do
      response.c[0].update!(latitude: 1.0)
      expect_dirty(response)
    end
  end

  describe "update form" do
    it "marks multiple dirty" do
      response.form.update!(name: "foo")
      expect_dirty(response)
      expect_dirty(response2)
      expect_clean(response3)
    end
  end

  describe "update user" do
    it "marks multiple dirty" do
      response.user.update!(name: "foo")
      expect_dirty(response)
      expect_dirty(response2)
      expect_clean(response3)
    end
  end

  describe "update question" do
    it "marks multiple dirty" do
      response.c[0].question.update!(code: "foo")
      expect_dirty(response)
      expect_dirty(response2)
      expect_clean(response3)
    end
  end

  describe "update questioning" do
    it "marks dirty" do
      response.c[0].questioning.update!(rank: 5)
      expect_dirty(response)
    end
  end

  describe "update qing_group" do
    it "marks dirty (rank)" do
      response3.c[1].qing_group.update!(rank: 5)
      expect_clean(response)
      expect_clean(response2)
      expect_dirty(response3)
    end

    it "marks dirty (repeatable)" do
      response3.c[1].qing_group.update!(repeatable: true)
      expect_clean(response)
      expect_clean(response2)
      expect_dirty(response3)
    end

    it "marks dirty (group_name_translations)" do
      response3.c[1].qing_group.update!(group_name_en: "foo")
      expect_clean(response)
      expect_clean(response2)
      expect_dirty(response3)
    end
  end

  def expect_dirty(response)
    expect(response.reload.dirty_json).to be_truthy
  end

  def expect_clean(response)
    expect(response.reload.dirty_json).to be_falsey
  end
end
