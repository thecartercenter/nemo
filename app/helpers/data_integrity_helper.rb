module DataIntegrityHelper

  # constructs html for a warning about published objects (form, questioning, question, option set)
  def published_warning(obj)
    type = obj.class.model_name.singular

    # get the proper i18n sub-key depending on if this is a standard obj or not
    # if it is a standard object, we need to say that a copy is published, not the obj itself, 
    # b/c that is not possible for std objs
    subkey = obj.is_standard? ? 'copy_published' : 'self_published'

    text = tmd("data_integrity.published_warnings.#{subkey}.#{type}")
    data_integrity_warning(:published_warning, text)
  end

  def has_answers_warning(obj)
    type = obj.class.model_name.singular
    text = tmd("data_integrity.has_answers_warnings.by_type.#{type}")
    data_integrity_warning(:has_answers_warning, text)
  end

  def appears_elsewhere_warning(obj)
    type = obj.class.model_name.singular
    text = tmd("data_integrity.appears_elsewhere_warnings.by_type.#{type}", :forms => obj.form_names)
    data_integrity_warning(:appears_elsewhere_warning, text)
  end

  def data_integrity_warning(type, text = nil)
    icon = content_tag(:i, '', :class => 'icon-warning-sign')
    text ||= tmd("data_integrity.#{type}")
    content_tag(:div, (icon + content_tag(:div, text)).html_safe, :class => "data_integrity_warning #{type}")
  end
end
