require 'test_helper'

class FormVersionTest < ActiveSupport::TestCase
  test "form version code generated on initialize" do
    fv = FormVersion.new
    assert_match(/[a-z]{#{FormVersion::CODE_LENGTH}}/, fv.code)
  end
  
  test "version codes are unique" do
    # create two fv's and check their codes are different
    fv1 = FormVersion.new
    fv2 = FormVersion.new
    assert_not_equal(fv1.code, fv2.code)
    
    # set one code = to other (this could happen by a fluke if second is init'd before first is saved)
    fv1.code = fv2.code
    assert_equal(fv1.code, fv2.code)
    
    # save one, then save the other. ensure the second one notices the duplication and adjusts
    assert(fv1.save)
    assert(fv2.save)
    assert_not_equal(fv1.code, fv2.code)
  end
  
  test "upgrade" do
    fv1 = FormVersion.create(:form_id => 99)
    fv2 = fv1.upgrade
    assert_equal(2, fv2.sequence)
    assert_equal(99, fv2.form_id)
    assert_not_equal(fv1.code, fv2.code)
    assert(!fv1.is_current)
    assert(fv2.is_current)
  end
end
