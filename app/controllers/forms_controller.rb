class FormsController < ApplicationController
  def index
    @forms = Form.published
    respond_to do |format|
      format.html
      format.xml{render(:content_type => "text/xml")}
    end
  end
  def show
    @form = Form.find(params[:id])
  end
end
