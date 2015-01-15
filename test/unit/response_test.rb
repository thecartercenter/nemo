require 'test_helper'

class ResponseTest < ActiveSupport::TestCase

  test "cache key" do
    @user = FactoryGirl.create(:user)
    @form = FactoryGirl.create(:form, :question_types => ['integer'])
    @form.publish!

    # ensure key changes on edits, creates, and deletes
    r1 = FactoryGirl.create(:response, :user => @user, :form => @form, :answer_values => [1])
    key1 = Response.per_mission_cache_key(get_mission)

    # create
    r2 = FactoryGirl.create(:response, :user => @user, :form => @form, :answer_values => [1])
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
    form.root_questionings.first.update_attribute(:required, true)
    form.publish!
    form.reload

    # Submit answer with first (and only) answer empty
    # This should show up as a missing response.
    invalid_response = FactoryGirl.build(:response, user: @user, form: form, answer_values: [''])
    assert_equal(false, invalid_response.valid?)
    assert_raise ActiveRecord::RecordInvalid do
      invalid_response.save!
    end
  end

  test "incomplete response will save if it is marked as incomplete" do
    @user = FactoryGirl.create(:user)

    form = FactoryGirl.create(:form, :question_types => %w(integer))
    form.root_questionings.first.required = true
    form.publish!
    form.reload

    r1 = FactoryGirl.create(:response, :user => @user, :form => form, :incomplete => true)
  end

  test "export sql should work" do
    FactoryGirl.create(:response, :form => FactoryGirl.create(:form, :question_types => %w(integer)), :answer_values => [1])
    res = ActiveRecord::Base.connection.execute(Response.export_sql(Response.unscoped))

    # result set should have one row since one Answer in db
    assert_equal(1, res.count)
  end

  test "incomplete responses should not disable constraints" do
    form = FactoryGirl.create(:form, :question_types => %w(integer))
    form.root_questionings.first.required = true
    form.root_questionings.first.question.update_attribute(:minimum, 10)
    form.publish!
    form.reload

    r1 = FactoryGirl.build(:response, :form => form, :incomplete => true, :answer_values => %w(9))
    assert_equal(false, r1.valid?)
    assert_match(/greater than/, r1.answers.first.errors.full_messages.join)
  end

  test "a user can checkout a response" do
    user = FactoryGirl.create(:user)

    response = FactoryGirl.build(:response)

    assert_nil(response.checked_out_at)
    assert_nil(response.checked_out_by_id)

    Timecop.freeze(Date.today) do
      response.check_out!(user)

      assert_equal(response.checked_out_at, Time.now)
      assert_equal(user, response.checked_out_by)
    end
  end

  test "a users previous checkout will be removed if they have more than one checkout" do
    user = FactoryGirl.create(:user)

    Timecop.freeze(Date.today) do
      r_previous = FactoryGirl.create(:response, :checked_out_at => Time.now, :checked_out_by => user)
      r_new      = FactoryGirl.build(:response)

      assert_nil(r_new.checked_out_at)
      assert_nil(r_new.checked_out_by_id)

      r_new.check_out!(user)
      r_previous.reload

      assert_equal(r_new.checked_out_at, Time.zone.parse(DateTime.now.to_s))
      assert_equal(user, r_new.checked_out_by)

      assert_nil(r_previous.checked_out_at)
      assert_nil(r_previous.checked_out_by_id)
    end

  end

end
