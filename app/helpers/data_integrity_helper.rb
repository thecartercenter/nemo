module DataIntegrityHelper

  # constructs html for a warning about published objects (form, questioning, question, option set)
  def published_warning(obj)
    type = obj.class.model_name.singular

    text = tmd("data_integrity.published_warnings.#{type}")
    data_integrity_warning(:published_warning, text)
  end

  def has_answers_warning(obj)
    type = obj.class.model_name.singular
    text = tmd("data_integrity.has_answers_warnings.by_type.#{type}")
    data_integrity_warning(:has_answers_warning, text)
  end

  def appears_elsewhere_warning(obj)
    type = obj.class.model_name.singular

    # get the appropriate list of names of related objects
    related = case obj.class.name
    when 'Question' then obj.form_names
    when 'OptionSet' then obj.question_codes
    else raise 'invalid object type for appears_elsewhere_warning'
    end

    text = tmd("data_integrity.appears_elsewhere_warnings.by_type.#{type}", :related => related)
    data_integrity_warning(:appears_elsewhere_warning, text)
  end

  def data_integrity_warning(type, text = nil)
    icon = content_tag(:i, '', :class => 'fa fa-exclamation-triangle')
    text ||= tmd("data_integrity.#{type}")
    content_tag(:div, (icon + content_tag(:div, text)).html_safe, :class => "form-warning alert alert-info #{type}", :id => type)
  end
end
