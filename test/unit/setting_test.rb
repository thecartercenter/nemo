require 'test_helper'

class SettingTest < ActiveSupport::TestCase

  setup do
    @setting = get_mission.setting
  end

  test "serialized locales are always symbols" do
    assert_equal(Symbol, @setting.preferred_locales.first.class)

    # try updating using the _str accessor
    @setting.update_attributes!(:preferred_locales_str => "fr,ar")

    # should still be symbols
    assert_equal(Symbol, @setting.preferred_locales.first.class)
  end

  test "locales with spaces should still be accepted" do
    @setting.update_attributes!(:preferred_locales_str => "fr , ar1")
    assert_equal([:fr, :ar], @setting.preferred_locales)
  end

  test "generate override code will generate a new six character code" do
    previous_code = @setting.override_code

    @setting.generate_override_code!

    assert_not_same(previous_code, @setting.override_code)
    assert_equal(6, @setting.override_code.size)
  end
end
