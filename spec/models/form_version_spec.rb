# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: form_versions
#
#  id         :uuid             not null, primary key
#  code       :string(255)      not null
#  is_current :boolean          default(TRUE), not null
#  number     :string(10)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  form_id    :uuid             not null
#
# Indexes
#
#  index_form_versions_on_code     (code) UNIQUE
#  index_form_versions_on_form_id  (form_id)
#  index_form_versions_on_number   (number) UNIQUE
#
# Foreign Keys
#
#  form_versions_form_id_fkey  (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

require "rails_helper"

describe FormVersion do
  let(:form) { create(:form) }

  it "form version code generated on initialize" do
    fv = FormVersion.new(form: form)
    expect(/[a-z]{#{FormVersion::CODE_LENGTH}}/).to match(fv.code)
  end

  it "form version number generated on initialize" do
    fv = FormVersion.new(form: form)
    expect(/[0-9]{10}/).to match(fv.number)
  end

  it "version codes are unique" do
    # create two fv's and check their codes are different
    fv1 = FormVersion.new(form: form)
    fv2 = FormVersion.new(form: form)
    expect(fv2.code).not_to eq(fv1.code)

    # set one code = to other (this could happen by a fluke if second is init'd before first is saved)
    fv1.code = fv2.code
    expect(fv2.code).to eq(fv1.code)

    # save one, then save the other. ensure the second one notices the duplication and adjusts
    expect(fv1.save).to be(true)
    expect(fv2.save).to be(true)
    expect(fv2.code).not_to eq(fv1.code)
  end

  it "version numbers are unique" do
    fv1 = FormVersion.new(form: form)
    fv2 = FormVersion.new(form: form)
    # by default they will be the same before saving
    expect(fv2.number).to eq(fv1.number)

    # save one, then save the other. ensure the second one notices the duplication and adjusts
    expect(fv1.save).to be(true)
    expect(fv2.save).to be(true)
    expect(fv2.number).not_to eq(fv1.number)
  end

  it "upgrade" do
    form.update_status(:live)
    fv1 = form.current_version
    expect(fv1).not_to be_nil
    old_v1_code = fv1.code
    old_v1_number = fv1.number

    # do the upgrade and save both forms
    fv2 = fv1.upgrade!
    fv1.save! & fv1.reload
    fv2.save! & fv2.reload

    # make sure values are updated properly
    expect(fv2.form_id).to eq(form.id)
    expect(fv2.code).not_to eq(fv1.code)
    expect(fv2.number).not_to eq(fv1.number)

    # make sure old v1 code/number didn't change
    expect(fv1.code).to eq(old_v1_code)
    expect(fv1.number).to eq(old_v1_number)

    # make sure current flags are set properly
    expect(fv1.is_current).to be(false)
    expect(fv2.is_current).to be(true)
  end

  it "form should create new version for itself when published" do
    expect(form.current_version).to be_nil

    # publish and check again
    form.update_status(:live)
    form.reload

    # ensure form_id is set properly on version object
    expect(form.current_version.form_id).to eq(form.id)

    # unpublish (shouldn't change)
    old_code = form.current_version.code
    old_number = form.current_version.number
    form.update_status(:draft)
    form.reload
    expect(form.current_version.code).to eq(old_code)
    expect(form.current_version.number).to eq(old_number)

    # publish again (shouldn't change)
    old_code = form.current_version.code
    old_number = form.current_version.number
    form.update_status(:live)
    form.reload
    expect(form.current_version.code).to eq(old_code)
    expect(form.current_version.number).to eq(old_number)

    # unpublish, set upgrade flag, and publish (should change)
    old_code = form.current_version.code
    old_number = form.current_version.number
    form.update_status(:draft)
    form.flag_for_upgrade!
    form.update_status(:live)
    form.reload
    expect(form.current_version.code).not_to eq(old_code)
    expect(form.current_version.number).not_to eq(old_number)

    # unpublish and publish (shouldn't change)
    old_code = form.current_version.code
    old_number = form.current_version.number
    form.update_status(:draft)
    form.update_status(:live)
    form.reload
    expect(form.current_version.code).to eq(old_code)
    expect(form.current_version.number).to eq(old_number)
  end
end
