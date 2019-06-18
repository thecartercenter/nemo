# frozen_string_literal: true

module CsvRenderable
  # Renders a file with the browser-appropriate MIME type for CSV data.
  # Sanitizes the filename.
  # filename - The filename to render, not including the .csv suffix.
  def render_csv(filename)
    filename = sanitize_filename("#{filename}.csv")

    if /msie/i.match?(request.env["HTTP_USER_AGENT"])
      headers["Pragma"] = "public"
      headers["Content-type"] = "text/plain"
      headers["Cache-Control"] = "no-cache, must-revalidate, post-check=0, pre-check=0"
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      headers["Expires"] = "0"
    else
      headers["Content-Type"] ||= "text/csv"
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end
  end

  # Removes any non-filename-safe characters from a string so that it can be used in a filename
  def sanitize_filename(filename)
    filename.strip.gsub(/[^0-9A-Za-z.\-]|\s/, "_")
  end
end
