module CsvRenderable

  # Renders a file with the browser-appropriate MIME type for CSV data.
  # Sanitizes the filename.
  # filename - The filename to render, not including the .csv suffix.
  def render_csv(filename)
    filename = sanitize_filename("#{filename}.csv")

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end

    render(:layout => false)
  end

  # removes any non-filename-safe characters from a string so that it can be used in a filename
  def sanitize_filename(filename)
    sanitized = filename.strip
    sanitized.gsub!(/^.*(\\|\/)/, '')
    # strip out non-ascii characters
    sanitized.gsub!(/[^0-9A-Za-z.\-]/, '_')
    sanitized
  end
end