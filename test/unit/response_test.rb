require 'test_helper'

class ResponseTest < ActiveSupport::TestCase

  test "cache key" do
    @user = FactoryGirl.create(:user)
    setup_form(:questions => %w(integer))

    # ensure key changes on edits, creates, and deletes
    r1 = FactoryGirl.create(:response, :user => @user, :form => @form, :_answers => [1])
    key1 = Response.per_mission_cache_key(get_mission)

    # create
    r2 = FactoryGirl.create(:response, :user => @user, :form => @form, :_answers => [1])
    key2 = Response.per_mission_cache_key(get_mission)
    assert_not_equal(key1, key2)

    # edit
    Timecop.travel(10.seconds) do
      r2.answers.first.update_attributes(:value => 2)
      key3 = Response.per_mission_cache_key(get_mission)
      assert_not_equal(key2, key3)
    end

    # destroy
    r2.destroy
    key4 = Response.per_mission_cache_key(get_mission)
    assert_not_equal(key2, key4)
  end

  test "incomplete response will not save if it is not marked as incomplete" do
    @user = FactoryGirl.create(:user)

    form = FactoryGirl.create(:form, :question_types => %w(integer))
    form.questionings.first.required = true
    form.publish!

    invalid_response = FactoryGirl.build(:response, :user => @user, :form => form)
    assert_equal(false, invalid_response.valid?)
    assert_raise ActiveRecord::RecordInvalid do
      invalid_response.save!
    end
  end

  test "incomplete response will save if it is marked as incomplete" do
    @user = FactoryGirl.create(:user)

    form = FactoryGirl.create(:form, :question_types => %w(integer))
    form.questionings.first.required = true
    form.publish!

    r1 = FactoryGirl.create(:response, :user => @user, :form => form, :incomplete => true)
  end
end
