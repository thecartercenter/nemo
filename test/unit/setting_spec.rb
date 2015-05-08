require 'spec_helper'

describe Setting do

  before do
    @setting = get_mission.setting
  end

  it "serialized locales are always symbols" do
    expect(@setting.preferred_locales.first.class).to eq(Symbol)

    # try updating using the _str accessor
    @setting.update_attributes!(:preferred_locales_str => "fr,ar")

    # should still be symbols
    expect(@setting.preferred_locales.first.class).to eq(Symbol)
  end

  it "locales with spaces should still be accepted" do
    @setting.update_attributes!(:preferred_locales_str => "fr , ar1")
    expect(@setting.preferred_locales).to eq([:fr, :ar])
  end

  it "generate override code will generate a new six character code" do
    previous_code = @setting.override_code

    @setting.generate_override_code!

    assert_not_same(previous_code, @setting.override_code)
    expect(@setting.override_code.size).to eq(6)
  end
end
