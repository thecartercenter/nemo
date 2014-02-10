# makes a standard looking form
module ElmoFormHelper

  # renders a form using the ElmoFormBuilder
  def elmo_form_for(obj, *args, &block)
    options = args.extract_options!
    form_for(obj, *(args << options.merge(:builder => ElmoFormBuilder, :html => {:class => "#{obj.class.model_name.singular}_form"})), &block)
  end

  # gets the mode a form should be displayed in: one of new, edit, or show
  def form_mode
    {:new => :new, :create => :new, :edit => :edit, :update => :edit, :show => :show}[controller.action_name.to_sym]
  end

  # renders the standard 'required' symbol, which is an asterisk
  def reqd_sym
    content_tag(:div, '*', :class => 'reqd_sym')
  end
end
