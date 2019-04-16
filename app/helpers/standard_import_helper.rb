# frozen_string_literal: true

# Used in index templates for objects that are importable.
module StandardImportHelper
  # generates and adds to the given array a link to show the standard import dialog, if appropriate
  def add_import_standard_link_if_appropriate(links)
    return unless !admin_mode? && @importable
    links << link_to(t("standard.import_standard.#{controller_name}"), "#", class: "import_standard")
  end

  # renders the modal/form for importing standard objs
  def standard_import_form
    render("standard_import/form")
  end
end
