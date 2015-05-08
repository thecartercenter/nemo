require 'spec_helper'

describe FormVersion do
  it "form version code generated on initialize" do
    fv = FormVersion.new
    assert_match(/[a-z]{#{FormVersion::CODE_LENGTH}}/, fv.code)
  end

  it "version codes are unique" do
    # create two fv's and check their codes are different
    fv1 = FormVersion.new
    fv2 = FormVersion.new
    assert_not_equal(fv1.code, fv2.code)

    # set one code = to other (this could happen by a fluke if second is init'd before first is saved)
    fv1.code = fv2.code
    expect(fv2.code).to eq(fv1.code)

    # save one, then save the other. ensure the second one notices the duplication and adjusts
    expect(fv1.save).to be true
    expect(fv2.save).to be true
    assert_not_equal(fv1.code, fv2.code)
  end

  it "upgrade" do
    f = create(:form)
    f.publish!
    fv1 = f.current_version
    assert_not_nil(fv1)
    old_v1_code = fv1.code

    # do the upgrade and save both forms
    fv2 = fv1.upgrade
    fv1.save!; fv1.reload
    fv2.save!; fv2.reload

    # make sure values are updated properly
    expect(fv2.sequence).to eq(2)
    expect(fv2.form_id).to eq(f.id)
    assert_not_equal(fv1.code, fv2.code)

    # make sure old v1 code didnt change
    expect(fv1.code).to eq(old_v1_code)

    # make sure current flags are set properly
    expect(fv1.is_current).to be false
    expect(fv2.is_current).to be true
  end
end
