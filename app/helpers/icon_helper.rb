module IconHelper

  FONT_AWESOME_ICON_MAPPINGS = {
    :broadcast => "bullhorn",
    :clone => "copy",
    :destroy => "trash-o",
    :edit => "pencil",
    :export => "download",
    :index => "list",
    :form => "file-text-o",
    :map => "globe",
    :mission => "briefcase",
    :new => "plus",
    :optionset => 'list-ul',
    :option_set => "list-ul",
    :print => "print",
    :publish => "arrow-up",
    :question => "question-circle",
    :remove => "times",
    :report => "bar-chart-o",
    :report_report => "bar-chart-o",
    :response => "check-circle-o",
    :setting => "gear",
    :show => "file-o",
    :sms => "comment",
    :sms_console => "laptop",
    :standard => "certificate",
    :submit => "share-square-o",
    :unpublish => "arrow-down",
    :user => "users"
  }

  # Returns the Font Awesome icon tag for the given object type or action.
  # Returns empty string if mapping not found.
  def icon_tag(key)
    (name = FONT_AWESOME_ICON_MAPPINGS[key.to_sym]) ? content_tag(:i, '', :class => "fa fa-#{name}") : ''
  end

  # Returns icon tag for standard icon if obj is standard, '' otherwise.
  def std_icon(obj)
    obj.respond_to?(:standardized?) && obj.standardized? ? icon_tag(:standard) : ''
  end
end