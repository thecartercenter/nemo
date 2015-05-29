require 'spec_helper'

describe OdkHelper do
  it "#required_value returns true for forms that don't allow incomplete responses" do
    f = create(:form, allow_incomplete: false)
    expect(helper.required_value(f)).to eq('true()')
  end

  it "#required_value returns ODK select statement for forms that allow incomplete responses" do
    f = create(:form, allow_incomplete: true)
    expect(helper.required_value(f)).to eq("selected\(/data/#{OdkHelper::IR_QUESTION}, 'no')")
  end
end
