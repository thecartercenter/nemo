module IconHelper

  FONT_AWESOME_ICON_MAPPINGS = {
    broadcast: "bullhorn",
    clone: "copy",
    destroy: "trash-o",
    drop_pin: "map-marker",
    edit: "pencil",
    export: "download",
    go_live: "play",
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
    pause: "pause",
    print: "print",
    publish: "arrow-up",
    question: "question-circle",
    remove: "times",
    report: "bar-chart-o",
    report_report: "bar-chart-o",
    response: "check-circle-o",
    hierarchicalresponse: "check-circle-o",
    setting: "gear",
    show: "file-o",
    sms: "comment",
    sms_guide: "comment",
    sms_console: "laptop",
    sms_message: "comment",
    standard: "certificate",
    submit: "share-square-o",
    unpublish: "arrow-down",
    user: "users",
    userimport: "users"
  }

  # Returns the Font Awesome icon tag for the given object type or action.
  # If no mapping is found, uses the given key verbatim in a an fa-* style icon name.
  def icon_tag(key, options = {})
    name = FONT_AWESOME_ICON_MAPPINGS[key.to_sym] || key.to_s
    options[:class] = ((options[:class] || "") + " fa fa-#{name} icon-#{key.to_s.dasherize}").strip
    content_tag(:i, "", options)
  end

  # Returns icon tag for standard icon if obj is standard (or boolean == true), '' otherwise.
  def std_icon(obj_or_bool)
    obj_or_bool.respond_to?(:standardized?) && obj_or_bool.standardized? || obj_or_bool == true ? icon_tag(:standard) : ''
  end
end
