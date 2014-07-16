module IconHelper

  FONT_AWESOME_ICON_MAPPINGS = {
    :clone => "copy",
    :destroy => "trash-o",
    :edit => "pencil",
    :map => "globe",
    :print => "print",
    :publish => "arrow-up",
    :remove => "times",
    :sms => "comment",
    :unpublish => "arrow-down",
    :submit => "share-square-o",
    :response => "check-circle-o",
    :report_report => "bar-chart-o",
    :report => "bar-chart-o",
    :form => "file-text-o",
    :question => "question-circle",
    :option_set => "list-ul",
    :optionset => 'list-ul',
    :user => "users",
    :broadcast => "bullhorn",
    :setting => "gear",
    :mission => "briefcase",
    :standard => "certificate"
  }

  # Returns the Font Awesome icon tag for the given object type.
  # Returns nil if mapping not found.
  def icon_tag(obj_type)
    (name = FONT_AWESOME_ICON_MAPPINGS[obj_type.to_sym]) ? content_tag(:i, '', :class => "fa fa-#{name}") : nil
  end

  # Returns icon tag for standard icon if obj is standard, '' otherwise.
  def std_icon(obj)
    obj.respond_to?(:standardized?) && obj.standardized? ? icon_tag(:standard) : ''
  end
end