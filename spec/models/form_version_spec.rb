require "rails_helper"

describe FormVersion do
  it "form version code generated on initialize" do
    fv = FormVersion.new
    assert_match(/[a-z]{#{FormVersion::CODE_LENGTH}}/, fv.code)
  end

  it "version codes are unique" do
    # create two fv's and check their codes are different
    fv1 = FormVersion.new
    fv2 = FormVersion.new
    expect(fv2.code).not_to eq(fv1.code)

    # set one code = to other (this could happen by a fluke if second is init'd before first is saved)
    fv1.code = fv2.code
    expect(fv2.code).to eq(fv1.code)

    # save one, then save the other. ensure the second one notices the duplication and adjusts
    expect(fv1.save).to be true
    expect(fv2.save).to be true
    expect(fv2.code).not_to eq(fv1.code)
  end

  it "upgrade" do
    f = create(:form)
    f.publish!
    fv1 = f.current_version
    expect(fv1).not_to be_nil
    old_v1_code = fv1.code

    # do the upgrade and save both forms
    fv2 = fv1.upgrade!
    fv1.save! & fv1.reload
    fv2.save! & fv2.reload

    # make sure values are updated properly
    expect(fv2.form_id).to eq(f.id)
    expect(fv2.code).not_to eq(fv1.code)

    # make sure old v1 code didnt change
    expect(fv1.code).to eq(old_v1_code)

    # make sure current flags are set properly
    expect(fv1.is_current).to be false
    expect(fv2.is_current).to be true
  end

  it "form should create new version for itself when published" do
    f = create(:form)
    expect(f.current_version).to be_nil

    # publish and check again
    f.publish!
    f.reload
    expect(f.current_version.sequence).to eq(1)

    # ensure form_id is set properly on version object
    expect(f.current_version.form_id).to eq(f.id)

    # unpublish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.reload
    expect(f.current_version.code).to eq(old)

    # publish again (shouldn't change)
    old = f.current_version.code
    f.publish!
    f.reload
    expect(f.current_version.code).to eq(old)

    # unpublish, set upgrade flag, and publish (should change)
    old = f.current_version.code
    f.unpublish!
    f.flag_for_upgrade!
    f.publish!
    f.reload
    expect(f.current_version.code).not_to eq(old)

    # unpublish and publish (shouldn't change)
    old = f.current_version.code
    f.unpublish!
    f.publish!
    f.reload
    expect(f.current_version.code).to eq(old)
  end
end
