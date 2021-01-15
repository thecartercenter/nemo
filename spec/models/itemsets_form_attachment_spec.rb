# frozen_string_literal: true

require "rails_helper"
require "fileutils"

describe ODK::ItemsetsFormAttachment, :odk do
  let(:form) { create(:form, question_types: question_types) }
  let(:question_types) { %w[integer] }
  subject(:itemsets_attachment) { ODK::ItemsetsFormAttachment.new(form: form) }

  describe "path" do
    before { allow(form).to receive(:id).and_return(42) }

    context "for live form" do
      before do
        allow(form).to receive(:draft?).and_return(false)
        allow(form).to receive(:published_changed_at).and_return(Time.zone.parse("2014-01-01 12:00:00 UTC"))
      end

      it "should be based on published_changed_at" do
        expect(itemsets_attachment.path).to eq("form-attachments/test/000042/itemsets-20140101_120000.csv")
      end
    end

    context "for draft form" do
      before do
        allow(form).to receive(:draft?).and_return(true)
      end

      it "should be based on current time" do
        Timecop.freeze("2014-02-01 12:00:00 UTC") do
          expect(itemsets_attachment.path).to eq("form-attachments/test/000042/itemsets-20140201_120000.csv")
        end
      end
    end
  end

  describe "priv_path" do
    it "should be correct" do
      allow(itemsets_attachment).to receive(:path).and_return("foo")
      expect(itemsets_attachment.priv_path).to eq(Rails.root.join("public/foo"))
    end
  end

  describe "md5" do
    context "for not yet generated itemset" do
      it "should raise IOerror" do
        expect { itemsets_attachment.md5 }.to raise_error(IOError)
      end
    end

    context "for generated itemset" do
      it "should return correct md5" do
        allow(itemsets_attachment).to receive(:file_contents).and_return("foo")
        expect(itemsets_attachment.md5).to eq("acbd18db4cc2f85cedef654fccc4a4d8") # This is md5 of "foo"
      end
    end
  end

  describe "empty?" do
    before do
      allow(itemsets_attachment).to receive(:decorated_form).and_return(double(needs_external_csv?: needs_external_csv))
    end

    context "with form needing external CSV" do
      let(:needs_external_csv) { true }
      it { is_expected.not_to be_empty }
    end

    context "with form not needing external CSV" do
      let(:needs_external_csv) { false }
      it { is_expected.to be_empty }
    end
  end

  describe "generate!" do
    let(:csv) { itemsets_attachment.send(:file_contents) }
    let(:external_csv_threshold) { 3 } # 3 means both multilevel and super_multilevel sets are included
    let(:priv_dir) { File.dirname(itemsets_attachment.priv_path) }

    before do
      configatron.preferred_locales = [:en]
      stub_const(ODK::OptionSetDecorator, "EXTERNAL_CSV_METHOD_THRESHOLD", external_csv_threshold)
    end

    after do
      # Clear out generated CSVs
      FileUtils.rm_rf(priv_dir)
    end

    context "for regular form" do
      let(:question_types) { %w[multilevel_select_one] }
      let(:dummy_path) { File.join(priv_dir, "itemsets-foo.csv") }

      before do
        # Create dummy older file.
        FileUtils.mkdir_p(priv_dir)
        FileUtils.touch(dummy_path)
      end

      it "should delete any previous files" do
        itemsets_attachment.ensure_generated
        expect(File.exist?(dummy_path)).to be(false)
      end
    end

    context "for multilevel sets" do
      let(:question_types) { %w[super_multilevel_select_one select_one multilevel_select_one] }
      let(:external_csv_threshold) { 7 } # 7 means only super_multilevel sets are included

      before do
        # Add a space and comma to test string enclosure in CSV.
        form.c[1].option_set.c[0].option.update!(name: "Cat, Large")
      end

      it "includes only the super_multilevel set" do
        itemsets_attachment.ensure_generated
        # Level names are repeated b/c each set is distinct.
        # Just a coincidence the names are the same in this CSV.
        expect(csv).to eq(prepare_itemset_expectation("multilevel.csv", form))
      end
    end

    context "for uneven multilevel sets" do
      let(:question_types) { %w[super_multilevel_select_one multilevel_select_one] }

      before do
        # Make the sets uneven so "None" must be inserted.
        form.c[0].option_set.root_node.c[1].children.each(&:destroy) # Delete all Plant's children
        form.c[1].option_set.root_node.c[0].children.each(&:destroy) # Delete Cat and Dog
      end

      it "should build file with correct contents" do
        itemsets_attachment.ensure_generated
        expect(csv).to eq(prepare_itemset_expectation("uneven_multilevel.csv", form))
      end
    end

    context "for muliple languages" do
      let(:question_types) { %w[multilevel_select_one] }

      before do
        configatron.preferred_locales = %i[en fr]
        form.c[0].option_set.options[0].update(name_fr: "Animale")
        form.c[0].option_set.options[1].update(name_fr: "Plante")
      end

      after do
        configatron.preferred_locales = [:en]
      end

      it "should build file with translations where available and fallback to English where not" do
        itemsets_attachment.ensure_generated
        expect(csv).to eq(prepare_itemset_expectation("multiple_languages.csv", form))
      end
    end

    context "for form with no option sets" do
      it "should not generate a file" do
        itemsets_attachment.ensure_generated
        expect(File.exist?(itemsets_attachment.priv_path)).to be(false)
      end
    end
  end

  def prepare_itemset_expectation(filename, form)
    nodes = form.option_sets.map(&:preordered_option_nodes).uniq.flatten
    option_sets = form.option_sets.map { |os| ODK::DecoratorFactory.decorate(os) }
    prepare_fixture("odk/itemsets/#{filename}",
      optsetcode: option_sets.map(&:odk_code),
      optcode: nodes.map(&:odk_code))
  end
end
