# encoding: utf-8
require 'spec_helper'
require 'fileutils'

describe ItemsetsFormAttachment do
  before do
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
        Timecop.freeze(Time.parse('2014-02-01 12:00:00 UTC')) do
          expect(@ifa.path).to eq "form-attachments/test/000042/itemsets-20140201_120000.csv"
        end
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
    context 'for not yet generated itemset' do
      it 'should raise IOerror' do
        expect{@ifa.md5}.to raise_error(IOError)
      end
    end

    context 'for generated itemset' do
      it 'should return correct md5' do
        allow(@ifa).to receive(:file_contents).and_return('foo')
        expect(@ifa.md5).to eq 'acbd18db4cc2f85cedef654fccc4a4d8' # This is md5 of 'foo'
      end
    end
  end

  describe 'empty?' do
    context 'for form with no option sets' do
      it 'should be true' do
        expect(@ifa.empty?).to be true
      end
    end

    context 'for regular form' do
      before do
        @os1 = create(:option_set, multi_level: true)
        allow(@form).to receive(:option_sets).and_return([@os1])
      end

      it 'should be false' do
        expect(@ifa.empty?).to be false
      end
    end
  end

  # Clean with truncation so we can guess IDs
  describe 'generate!', clean_with_truncation: true do
    before do
      configatron.preferred_locales = [:en]
    end

    context 'for regular form' do
      before do
        @os1 = create(:option_set)
        allow(@form).to receive(:option_sets).and_return([@os1])
      end

      it 'should delete any previous files' do
        # Create dummy older file.
        FileUtils.mkdir_p(@ifa.send(:priv_dir))
        dummy = File.join(@ifa.send(:priv_dir), 'itemsets-foo.csv')
        FileUtils.touch(dummy)

        @ifa.send(:generate!)
        expect(File.exists?(dummy)).to be false
      end
    end

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
        expect(@ifa.send(:file_contents)).to eq [
          # Level names are repeated b/c each set is distinct. Just a coincidence the names are same here.
          'list_name,name,label::English,parent_id',
          'os1,on2,Animal,',
          'os1,on3,Vertebrate,on2',
          'os1,on4,Cat,on3',
          'os1,on5,Dog,on3',
          'os1,on6,Invertebrate,on2',
          'os1,on7,Lobster,on6',
          'os1,on8,Jellyfish,on6',
          'os1,on9,Plant,',
          'os1,on10,Tree,on9',
          'os1,on11,Oak,on10',
          'os1,on12,Pine,on10',
          'os1,on13,Flower,on9',
          'os1,on14,Tulip,on13',
          'os1,on15,Daisy,on13',
          'os2,on17,"Cat, Large",',
          'os2,on18,Dog,',
          'os3,on20,Animal,',
          'os3,on21,Cat,on20',
          'os3,on22,Dog,on20',
          'os3,on23,Plant,',
          'os3,on24,Tulip,on23',
          'os3,on25,Oak,on23',
          ''
        ].join("\n")
      end
    end

    context 'for uneven multilevel sets' do
      before do
        @os1 = create(:option_set, super_multi_level: true)
        @os2 = create(:option_set, multi_level: true)

        # Make the sets uneven so 'None' must be inserted.
        @os1.root_node.c[1].children.each{ |c| c.destroy } # Delete all Plant's children
        @os2.root_node.c[0].children.each{ |c| c.destroy } # Delete Cat and Dog

        allow(@form).to receive(:option_sets).and_return([@os1, @os2])
      end

      it 'should build file with correct contents' do
        @ifa.send(:generate!)
        expect(@ifa.send(:file_contents)).to eq [
          # Level names are repeated b/c each set is distinct. Just a coincidence the names are same here.
          'list_name,name,label::English,parent_id',
          'os1,on2,Animal,',
          'os1,on3,Vertebrate,on2',
          'os1,on4,Cat,on3',
          'os1,on5,Dog,on3',
          'os1,on6,Invertebrate,on2',
          'os1,on7,Lobster,on6',
          'os1,on8,Jellyfish,on6',
          'os1,on9,Plant,',
          'os1,none,[Blank],on9',
          'os1,none,[Blank],none',
          'os2,on17,Animal,',
          'os2,none,[Blank],on17',
          'os2,on20,Plant,',
          'os2,on21,Tulip,on20',
          'os2,on22,Oak,on20',
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
        expect(@ifa.send(:file_contents)).to eq [
          'list_name,name,label::English,label::Français,parent_id',
          'os1,on2,Animal,Animale,',
          'os1,on3,Cat,,on2',
          'os1,on4,Dog,,on2',
          'os1,on5,Plant,Plante,',
          'os1,on6,Tulip,,on5',
          'os1,on7,Oak,,on5',
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
