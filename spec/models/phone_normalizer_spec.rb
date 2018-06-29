require "rails_helper"

describe PhoneNormalizer do
  describe '#is_shortcode?' do
    it "is false for blank inputs" do
      [nil, "", " ", "\t"].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_falsey
      end
    end

    it "is true for inputs containing a letter" do
      ["ELMO", "TCC4U"].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_truthy
      end
    end

    it "is true for numeric inputs shorter than 7 characters" do
      ["543210", "1976", "(123)"].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_truthy
      end
    end

    it "is true for numeric inputs shorter than 7 characters after removing country code" do
      ["+2422800", "+507249992", "+60999323", "2422800", "+242 (2800)"].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_truthy
      end
    end

    it "is false for numeric inputs longer than 7 characters" do
      ["+18005551212", "(770) 555-1212"].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_falsey
      end
    end
  end

  describe '#normalize' do
    it "returns nil for blank inputs" do
      [nil, "", " ", "\t", "+ "].each do |phone|
        expect(PhoneNormalizer.normalize(phone)).to be_nil
      end
    end

    it "trims spaces" do
      [" 12345678", "12345678 ", "  12345678   "].each do |phone|
        expect(PhoneNormalizer.normalize(phone)).to eq("+12345678")
      end
    end

    it "returns the value itself for short codes" do
      ["54321"].each do |phone|
        expect(PhoneNormalizer.normalize(phone)).to eq(phone)
      end
    end

    it "returns the normalized value for full numbers" do
      expect(PhoneNormalizer.normalize("1-800-555-1212")).to eq("+18005551212")
      expect(PhoneNormalizer.normalize("+49-89-636-48018")).to eq("+498963648018")
    end
  end
end
