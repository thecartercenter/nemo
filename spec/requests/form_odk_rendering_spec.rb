require 'spec_helper'
require 'xml'

describe 'form rendering for odk' do
  before do
    @user = create(:user)
    @form = create(:sample_form)
    @form.publish!
    login(@user)
    get(form_path(@form, format: :xml))
  end

  it 'should render proper xml' do
    expect(response).to be_success

    # Parse the XML and tidy.
    doc = XML::Parser.string(response.body, options: XML::Parser::Options::NOBLANKS).parse.root
    expect(doc.to_s).to eq File.read(File.expand_path('../../expectations/sample_form_odk.xml', __FILE__)).strip
  end
end
