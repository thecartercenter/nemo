# frozen_string_literal: true

module StandardImportHelper
  # generates and adds to the given array a link to show the standard import dialog, if appropriate
  def add_import_standard_link_if_appropriate(links)
    links << link_to(t("standard.import_standard.#{controller_name}"), "#", class: "import_standard") if !admin_mode? && @importable
  end

  # renders the modal/form for importing standard objs
  def standard_import_form
    render("standard_import/form")
  end
end
