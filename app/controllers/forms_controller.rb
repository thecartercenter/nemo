class FormsController < ApplicationController
  def index
    @subindex = Subindex.find_and_update(session, current_user, "Form", params[:page])
    # get the options
    @forms = Form.published(@subindex.params)
    render_appropriate_format
  end
  def show
    @form = Form.find_eager(params[:id])
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
