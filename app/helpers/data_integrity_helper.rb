module DataIntegrityHelper

  # constructs html for a warning about published objects (form, questioning, question, option set)
  def published_warning(obj)
    # get primary text
    type = obj.class.model_name.singular
    text = [tmd("data_integrity.published_warnings.by_type.#{type}")]

    # add sms piece if applicable
    smsable = obj.is_a?(Form) ? obj.smsable? : obj.form_smsable?
    text << tmd("data_integrity.published_warnings.sms") if smsable

    # add odk piece
    text << tmd("data_integrity.published_warnings.odk")

    # create tag and return
    data_integrity_warning(text.join(' ').html_safe)
  end

  def has_answers_warning(obj)
    type = obj.class.model_name.singular
    text = tmd("data_integrity.has_answers_warnings.by_type.#{type}")
    data_integrity_warning(text)
  end

  def appears_elsewhere_warning(obj)
    type = obj.class.model_name.singular
    text = tmd("data_integrity.appears_elsewhere_warnings.by_type.#{type}", :forms => obj.form_names)
    data_integrity_warning(text)
  end

  def data_integrity_warning(text)
    icon = content_tag(:i, '', :class => 'icon-warning-sign')
    content_tag(:div, (icon + content_tag(:div, text)).html_safe, :class => 'data_integrity_warning')
  end
end
