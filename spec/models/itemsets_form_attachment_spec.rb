# encoding: utf-8
require 'spec_helper'
require 'fileutils'

describe ItemsetsFormAttachment do
  before do
    configatron.preferred_locales = [:en]
    @form = create(:form)
    @ifa = ItemsetsFormAttachment.new(form: @form)
  end

  describe 'path' do
    before { allow(@form).to receive(:id).and_return(42) }

    context 'for published form' do
      before do
        allow(@form).to receive(:published?).and_return(true)
        allow(@form).to receive(:pub_changed_at).and_return(Time.parse('2014-01-01 12:00:00 UTC'))
      end

      it 'should be based on pub_changed_at' do
        expect(@ifa.path).to eq "form-attachments/test/000042/itemsets-20140101_120000.csv"
      end
    end

    context 'for unpublished form' do
      before do
        allow(@form).to receive(:published?).and_return(false)
      end

      it 'should be based on current time' do
        Timecop.freeze(Time.parse('2014-02-01 12:00:00 UTC'))
        expect(@ifa.path).to eq "form-attachments/test/000042/itemsets-20140201_120000.csv"
      end
    end
  end

  describe 'priv_path' do
    it 'should be correct' do
      allow(@ifa).to receive(:path).and_return('foo')
      allow(Rails).to receive(:root).and_return('/some/place')
      expect(@ifa.send(:priv_path)).to eq '/some/place/public/foo'
    end
  end

  describe 'md5' do

  end

  # Clean with truncation so we can guess IDs
  describe 'generate!', clean_with_truncation: true do
    context 'for multilevel sets' do
      before do
        @os1 = create(:option_set, super_multi_level: true)
        @os2 = create(:option_set)
        @os2.options.first.update_attributes!(name: 'Cat, Large') # Add a space and comma to test enclosure.
        @os3 = create(:option_set, multi_level: true)
        allow(@form).to receive(:option_sets).and_return([@os1, @os2, @os3])
      end

      it 'should build file with correct contents' do
        @ifa.send(:generate!)
        expect(File.read(@ifa.send(:priv_path))).to eq [
          # Level names are repeated b/c each set is distinct. Just a coincidence the names are same here.
          'list_name,name,label::English,os1_lev1,os1_lev2,os3_lev1',
          'os1,o1,Animal,,,',
          'os1,o2,Vertebrate,o1,,',
          'os1,o3,Cat,o1,o2,',
          'os1,o4,Dog,o1,o2,',
          'os1,o5,Invertebrate,o1,,',
          'os1,o6,Lobster,o1,o5,',
          'os1,o7,Jellyfish,o1,o5,',
          'os1,o8,Plant,,,',
          'os1,o9,Tree,o8,,',
          'os1,o10,Oak,o8,o9,',
          'os1,o11,Pine,o8,o9,',
          'os1,o12,Flower,o8,,',
          'os1,o13,Tulip,o8,o12,',
          'os1,o14,Daisy,o8,o12,',
          'os2,o15,"Cat, Large",,,',
          'os2,o16,Dog,,,',
          'os3,o17,Animal,,,',
          'os3,o18,Cat,,,o17',
          'os3,o19,Dog,,,o17',
          'os3,o20,Plant,,,',
          'os3,o21,Tulip,,,o20',
          'os3,o22,Oak,,,o20',
          ''
        ].join("\n")
      end
    end

    context 'for muliple languages' do
      before do
        configatron.preferred_locales = [:en, :fr]
        @os1 = create(:option_set, multi_level: true)
        @os1.options[0].update_attributes(name_fr: 'Animale')
        @os1.options[1].update_attributes(name_fr: 'Plante')
        allow(@form).to receive(:option_sets).and_return([@os1])
      end

      it 'should build file with correct contents' do
        @ifa.send(:generate!)
        expect(File.read(@ifa.send(:priv_path))).to eq [
          'list_name,name,label::English,label::Français,os1_lev1',
          'os1,o1,Animal,Animale,',
          'os1,o2,Cat,,o1',
          'os1,o3,Dog,,o1',
          'os1,o4,Plant,Plante,',
          'os1,o5,Tulip,,o4',
          'os1,o6,Oak,,o4',
          ''
        ].join("\n")
      end

      after do
        configatron.preferred_locales = [:en]
      end
    end

    context 'for form with no option sets' do
      it 'should not generate a file' do
        @ifa.ensure_generated
        expect(File.exists?(@ifa.send(:priv_path))).to be false
      end
    end

    after do
      # Clear out CSVs
      FileUtils.rm_rf(@ifa.send(:priv_dir))
    end
  end
end
