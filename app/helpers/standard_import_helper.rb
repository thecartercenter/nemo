# frozen_string_literal: true

module StandardImportHelper
  # generates and adds to the given array a link to show the standard import dialog, if appropriate
  def add_import_standard_link_if_appropriate(links)
    return if admin_mode? || !@importable
    links << link_to(t("action_links.import_standard"), "#", class: "import_standard")
  end

  # renders the modal/form for importing standard objs
  def standard_import_form
    render("standard_import/form")
  end
end
