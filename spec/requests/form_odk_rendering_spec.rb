require 'spec_helper'

# We need to clean with truncation here b/c we use hard coded id's in expectation.
describe 'form rendering for odk', clean_with_truncation: true do
  before do
    @user = create(:user)
    login(@user)
  end

  context 'sample form' do
    before do
      @form = create(:form, question_types: %w(text long_text integer decimal location select_one multilevel_select_one select_multiple datetime date time))
      @form.publish!
      get(form_path(@form, format: :xml))
    end

    it 'should render proper xml' do
      expect(response).to be_success

      # Parse the XML and tidy.
      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/odk/sample_form.xml', __FILE__))
    end
  end

  context 'grid form' do
    before do
      first_question = create(:question, qtype_name: 'select_one')
      second_question = create(:question, qtype_name: 'select_one', option_set: first_question.option_set)

      @form = create(:form, questions: [[first_question, second_question]])
      @form.publish!
      get(form_path(@form, format: :xml))
    end

    it 'should render proper xml' do
      expect(response).to be_success

      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/odk/grid_form.xml', __FILE__))
    end
  end

  context 'group form' do
    before do
      @form = create(:form, question_types: [['text', 'text', 'text', 'text']])
      @form.questionings.last.update_attributes!(hidden: true, required: true)
      @form.publish!

      get(form_path(@form, format: :xml))
    end

    it 'should render proper xml' do
      expect(response).to be_success

      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/odk/group_form.xml', __FILE__))
    end
  end

  context 'repeat group form' do
    before do
      @form = create(:form, question_types: [['text', 'text', 'text', 'text']])
      @form.questionings.last.update_attributes!(hidden: true, required: true)
      @form.child_groups.first.update_attributes!(repeats: true)
      @form.publish!

      get(form_path(@form, format: :xml))
    end

    it 'should render proper xml' do
      expect(response).to be_success

      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/odk/repeat_group_form.xml', __FILE__))
    end
  end

  context 'group form with multilevel select' do
    before do
      @form = create(:form, question_types: [['text', 'date', 'multilevel_select_one', 'integer']])
      @form.publish!

      get(form_path(@form, format: :xml))
    end

    it 'should render proper xml' do
      expect(response).to be_success

      doc = Nokogiri::XML(response.body) { |config| config.noblanks }
      expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/odk/group_form_with_multilevel.xml', __FILE__))
    end
  end

    context 'repeat group form with multilevel select' do
      before do
        @form = create(:form, question_types: [['text', 'date', 'multilevel_select_one', 'integer']])
        @form.child_groups.first.update_attributes!(repeats: true)
        @form.publish!

        get(form_path(@form, format: :xml))
      end

      it 'should render proper xml' do
        expect(response).to be_success

        doc = Nokogiri::XML(response.body) { |config| config.noblanks }
        expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/odk/repeat_group_form_with_multilevel.xml', __FILE__))
      end
    end
end
