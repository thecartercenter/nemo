require 'test_helper'

class OptionSetTest < ActiveSupport::TestCase

  test "creating an option set without explicit ranks should add default ranks" do
    os = create_option_set(["S", "V", "X"])
    assert_ranks(os, {"S" => 1, "V" => 2, "X" => 3})
  end
  
  test "creating an option set with explicit ranks should work regardless of submission order" do
    os = create_option_set({"S" => 2, "V" => 1, "X" => 3})
    assert_ranks(os, {"V" => 1, "S" => 2, "X" => 3})
  end
  
  test "editing an option set with invalid explicit ranks should correct them" do
    os = create_option_set({"S" => 1, "V" => 2, "X" => 3})
    
    # change the rank of 'V' to a too-high number
    os.option_settings[1].rank = 9
    os.save!
    
    # the rank of 'V' should have been repaired down to 3, and 'X' should shift to 2
    assert_ranks(os, {"S" => 1, "X" => 2, "V" => 3})
  end

  test "a nullifyied rank should be corrected" do
    os = create_option_set({"S" => 1, "V" => 2, "X" => 3})
    
    # change the rank of 'V' to nil
    os.option_settings[1].rank = nil
    os.save!
    
    # 'V' should move to the end
    assert_ranks(os, {"S" => 1, "X" => 2, "V" => 3})
  end
  
  test "options method should return properly sorted options" do
    os = create_option_set({"S" => 2, "V" => 1, "X" => 3})
    os.reload
    assert_equal("V", os.options[0].name_en)
    assert_equal("S", os.options[1].name_en)
    assert_equal("X", os.options[2].name_en)
  end
  
  private
    def create_option_set(options)
      os = OptionSet.new(:name => "test")
      options.each do |o|
        # if o is an array then we have an explicit rank
        if o.is_a?(Array)
          name = o[0]
          rank = o[1]
        # else we have no explicit rank, so leave nil
        else
          name = o
          rank = nil
        end
        os.option_settings.new(:option => Option.new(:name_en => name), :rank => rank)
      end
      os.save!
      os
    end
    
    # checks that each rank is as expected
    def assert_ranks(os, ranks)
      os.option_settings.each do |o|
        assert_equal(ranks[o.option.name_en], o.rank)
      end
    end
end