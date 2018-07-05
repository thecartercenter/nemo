# encoding: utf-8
require "rails_helper"
require "fileutils"

describe ItemsetsFormAttachment, :odk do
  let(:form) { create(:form) }
  let(:ifa) { ItemsetsFormAttachment.new(form: form) }

  after do
    # Clear out CSVs
    FileUtils.rm_rf(ifa.send(:priv_dir))
  end

  describe "path" do
    before { allow(form).to receive(:id).and_return(42) }

    context "for published form" do
      before do
        allow(form).to receive(:published?).and_return(true)
        allow(form).to receive(:pub_changed_at).and_return(Time.parse("2014-01-01 12:00:00 UTC"))
      end

      it "should be based on pub_changed_at" do
        expect(ifa.path).to eq "form-attachments/test/000042/itemsets-20140101_120000.csv"
      end
    end

    context "for unpublished form" do
      before do
        allow(form).to receive(:published?).and_return(false)
      end

      it "should be based on current time" do
        Timecop.freeze(Time.parse("2014-02-01 12:00:00 UTC")) do
          expect(ifa.path).to eq "form-attachments/test/000042/itemsets-20140201_120000.csv"
        end
      end
    end
  end

  describe "priv_path" do
    it "should be correct" do
      allow(ifa).to receive(:path).and_return("foo")
      allow(Rails).to receive(:root).and_return("/some/place")
      expect(ifa.send(:priv_path)).to eq "/some/place/public/foo"
    end
  end

  describe "md5" do
    context "for not yet generated itemset" do
      it "should raise IOerror" do
        expect{ ifa.md5 }.to raise_error(IOError)
      end
    end

    context "for generated itemset" do
      it "should return correct md5" do
        allow(ifa).to receive(:file_contents).and_return("foo")
        expect(ifa.md5).to eq "acbd18db4cc2f85cedef654fccc4a4d8" # This is md5 of "foo"
      end
    end
  end

  describe "empty?" do
    context "for form with no option sets" do
      it "should be true" do
        expect(ifa.empty?).to be true
      end
    end

    context "for regular form" do
      let(:os1) { create(:option_set, multilevel: true) }

      before do
        allow(form).to receive(:option_sets).and_return([os1])
      end

      it "should be false" do
        expect(ifa.empty?).to be false
      end
    end
  end

  describe "generate!" do
    let(:csv) { ifa.send(:file_contents) }

    before do
      configatron.preferred_locales = [:en]
      allow(form).to receive(:option_sets).and_return(opt_sets)
    end

    context "for regular form" do
      let(:os1) { create(:option_set) }
      let(:opt_sets) { [os1] }

      it "should delete any previous files" do
        # Create dummy older file.
        FileUtils.mkdir_p(ifa.send(:priv_dir))
        dummy = File.join(ifa.send(:priv_dir), "itemsets-foo.csv")
        FileUtils.touch(dummy)

        ifa.send(:generate!)
        expect(File.exists?(dummy)).to be false
      end
    end

    context "for multilevel sets" do
      let(:os1) { create(:option_set, super_multilevel: true) }
      let(:os2) { create(:option_set) }
      let(:os3) { create(:option_set, multilevel: true) }
      let(:opt_sets) { [os1, os2, os3] }

      before do
        os2.options.first.update_attributes!(name: "Cat, Large") # Add a space and comma to test enclosure.
      end

      it "should build file with correct contents" do
        ifa.send(:generate!)
        # Level names are repeated b/c each set is distinct.
        # Just a coincidence the names are the same in this CSV.
        expect(csv).to eq prepare_itemset_expectation("multilevel.csv", opt_sets)
      end
    end

    context "for uneven multilevel sets" do
      let(:os1) { create(:option_set, super_multilevel: true) }
      let(:os2) { create(:option_set, multilevel: true) }
      let(:opt_sets) { [os1, os2] }

      before do
        # Make the sets uneven so "None" must be inserted.
        os1.root_node.c[1].children.each{ |c| c.destroy } # Delete all Plant"s children
        os2.root_node.c[0].children.each{ |c| c.destroy } # Delete Cat and Dog
      end

      it "should build file with correct contents" do
        ifa.send(:generate!)
        expect(csv).to eq prepare_itemset_expectation("uneven_multilevel.csv", opt_sets)
      end
    end

    context "for muliple languages" do
      let(:os1) { create(:option_set, multilevel: true) }
      let(:opt_sets) { [os1] }

      before do
        configatron.preferred_locales = [:en, :fr]
        os1.options[0].update_attributes(name_fr: "Animale")
        os1.options[1].update_attributes(name_fr: "Plante")
      end

      it "should build file with correct contents" do
        ifa.send(:generate!)
        expect(csv).to eq prepare_itemset_expectation("multiple_languages.csv", opt_sets)
      end

      after do
        configatron.preferred_locales = [:en]
      end
    end

    context "for form with no option sets" do
      let(:opt_sets) { [] }

      it "should not generate a file" do
        ifa.ensure_generated
        expect(File.exists?(ifa.send(:priv_path))).to be false
      end
    end
  end

  def prepare_itemset_expectation(filename, option_sets)
    nodes = option_sets.map(&:preordered_option_nodes).uniq.flatten
    prepare_fixture("odk/itemsets/#{filename}",
      optsetid: option_sets.map(&:id),
      optcode: nodes.map(&:odk_code)
    )
  end
end
