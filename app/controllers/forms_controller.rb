class FormsController < ApplicationController
  def show
    @form = Form.find(params[:id])
    respond_to do |format|
      #format.html
      format.xml{render(:xml => @users)}
    end
  end
end
