module IconHelper

  FONT_AWESOME_ICON_MAPPINGS = {
    broadcast: "bullhorn",
    clone: "copy",
    destroy: "trash-o",
    edit: "pencil",
    export: "download",
    import: "upload",
    index: "list",
    form: "file-text-o",
    map: "globe",
    mission: "briefcase",
    new: "plus",
    operation: 'gears',
    optionset: 'list-ul',
    option_set: "list-ul",
    optionsetimport: "list-ul",
    option_set_import: "list-ul",
    print: "print",
    publish: "arrow-up",
    question: "question-circle",
    remove: "times",
    report: "bar-chart-o",
    report_report: "bar-chart-o",
    response: "check-circle-o",
    setting: "gear",
    show: "file-o",
    sms: "comment",
    sms_console: "laptop",
    sms_message: "comment",
    standard: "certificate",
    submit: "share-square-o",
    unpublish: "arrow-down",
    user: "users"
  }

  # Returns the Font Awesome icon tag for the given object type or action.
  # Returns empty string if mapping not found.
  def icon_tag(key, options = {})
    name = FONT_AWESOME_ICON_MAPPINGS[key.to_sym] || key.to_s
    content_tag(:i, '', options.merge(class: "fa fa-#{name} icon-#{key}"))
  end

  # Returns icon tag for standard icon if obj is standard (or boolean == true), '' otherwise.
  def std_icon(obj_or_bool)
    obj_or_bool.respond_to?(:standardized?) && obj_or_bool.standardized? || obj_or_bool == true ? icon_tag(:standard) : ''
  end
end
