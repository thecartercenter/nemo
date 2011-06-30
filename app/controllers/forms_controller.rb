class FormsController < ApplicationController
  def index
    @forms = Form.published
    render_appropriate_format
  end
  def show
    @form = Form.find(params[:id])
    render_appropriate_format
  end
  private
    def render_appropriate_format
      respond_to do |format|
        format.html
        format.xml do
          render(:content_type => "text/xml")
          response.headers['X-OpenRosa-Version'] = "1.0"
        end
      end
    end
end
