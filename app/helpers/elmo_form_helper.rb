# makes a standard looking form
module ElmoFormHelper

  # renders a form using the ElmoFormBuilder
  def elmo_form_for(obj, *args, &block)
    options = args.extract_options!
    (base_errors(obj, options) +
      form_for(obj, *(args << options.merge(:builder => ElmoFormBuilder, :html => {:class => "#{obj.class.model_name.singular}_form"})), &block)).html_safe
  end

  # renders a set of form fields using the ElmoFormBuilder
  def elmo_fields_for(field_name, obj, *args, &block)
    options = args.extract_options!

    (base_errors(obj, options) +
      fields_for(field_name, obj, *(args << options.merge(:builder => ElmoFormBuilder)), &block)).html_safe
  end

  # gets the mode a form should be displayed in: one of new, edit, or show
  def form_mode
    {:new => :new, :create => :new, :edit => :edit, :update => :edit, :show => :show}[controller.action_name.to_sym]
  end

  # renders the standard 'required' symbol, which is an asterisk
  def reqd_sym
    content_tag(:div, '*', :class => 'reqd_sym')
  end

  def base_errors(obj, options)
    # we include errors on the :base of the object
    # unless we are explicitly told not to
    options.delete(:show_errors) == false ? '' : content_tag(:div, obj.errors[:base].join(' '), :class => 'form-errors')
  end
end
