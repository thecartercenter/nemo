require "spec_helper"

module Odk
  describe FormDecorator, :odk, :reset_factory_sequences do
    describe "needs_manifest?", :odk do
      context "for form with single level option sets only" do
        before { @form = create(:form, question_types: %w(select_one)) }
        it "should return false" do
          decorated_form = decorate(@form)
          expect(decorated_form.needs_manifest?).to be false
        end
      end
      context "for form with multi level option set" do
        before { @form = create(:form, question_types: %w(select_one multilevel_select_one)) }
        it "should return true" do
          decorated_form = decorate(@form)
          expect(decorated_form.needs_manifest?).to be true
        end
      end
    end

    def decorate(obj)
      Odk::DecoratorFactory.decorate(obj)
    end
  end
end

