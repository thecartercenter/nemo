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

  test "export sql should work" do
    FactoryGirl.create(:response, :form => FactoryGirl.create(:form, :question_types => %w(integer)), :_answers => [1])
    res = ActiveRecord::Base.connection.execute(Response.export_sql(Response.unscoped))

    # result set should have one row since one Answer in db
    assert_equal(1, res.count)
  end

  test "incomplete responses should not disable constraints" do
    form = FactoryGirl.create(:form, :question_types => %w(integer))
    form.questionings.first.required = true
    form.questionings.first.question.minimum = 10
    form.publish!

    r1 = FactoryGirl.build(:response, :form => form, :incomplete => true, :_answers => %w(9))
    assert_equal(false, r1.valid?)
    assert_match(/greater than/, r1.answers.first.errors.full_messages.join)
  end
end
