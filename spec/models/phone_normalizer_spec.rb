require 'spec_helper'

describe PhoneNormalizer do
  describe '#is_shortcode?' do
    it 'is false for blank inputs' do
      [nil, '', ' ', "\t"].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_falsey
      end
    end

    it 'is true for inputs containing a letter' do
      ['ELMO', 'TCC4U'].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_truthy
      end
    end

    it 'is true for numeric inputs shorter than 7 characters' do
      ['543210', '1976', '(123)'].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_truthy
      end
    end

    it 'is false for numeric inputs longer than 7 characters' do
      ['+18005551212', '(770) 555-1212'].each do |phone|
        expect(PhoneNormalizer.is_shortcode?(phone)).to be_falsey
      end
    end
  end
end
