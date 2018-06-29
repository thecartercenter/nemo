require "rails_helper"

describe Base36 do
  describe ".digits_needed" do
    it "should return 1 for numbers between 0 and 36" do
      (0..35).each do |i|
        expect(Base36.digits_needed(i)).to eq 1
      end
    end

    it "should return 2 for numbers between 36 and 1296" do
      (36..1295).each do |i|
        expect(Base36.digits_needed(i)).to eq 2
      end
    end

    it "should work for large numbers" do
      expect(Base36.digits_needed(5_555_555_555)).to eq 7
    end
  end

  describe ".offset" do
    it "should return 0 if the length is 1" do
      expect(Base36.offset(1)).to eq 0
    end

    it "should return 36 if the length is 2" do
      expect(Base36.offset(2)).to eq 36
    end

    it "should return 1296 if the length is 3" do
      expect(Base36.offset(3)).to eq 1296
    end

    it "should return 46,656 if the length is 4" do
      expect(Base36.offset(4)).to eq 46_656
    end

    it "should return 1,679,616 if the length is 5" do
      expect(Base36.offset(5)).to eq 1_679_616
    end

    it "should return 60,466,176 if the length is 6" do
      expect(Base36.offset(6)).to eq 60_466_176
    end

    it "should return 2,176,782,336 if the length is 7" do
      expect(Base36.offset(7)).to eq 2_176_782_336
    end
  end

  describe ".to_padded_base36" do
    it "should create base36 strings of the same length for large values of n" do
      first_sequence = 1
      last_sequence = 2_000_000_000
      required_length = Base36.digits_needed(last_sequence)
      first_code = Base36.to_padded_base36(first_sequence, length: required_length)
      last_code = Base36.to_padded_base36(last_sequence, length: required_length)
      expect(first_code).to eq "100001"
      expect(first_code.length).to eq last_code.length
    end
  end
end
