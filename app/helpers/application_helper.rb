module ApplicationHelper
  def show_flash_and_form_errors(object = nil)
    render("layouts/flash", :flash => flash, :object => object)
  end
end
