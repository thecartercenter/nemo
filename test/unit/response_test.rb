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
end