# frozen_string_literal: true

ActionController::Renderers.add(:csv) do |obj, options|
  filename = options[:filename] || options[:template]
  filename = filename.strip.gsub(/[^0-9A-Za-z.\-]|\s/, "_")
  disposition = "attachment; file=\"#{filename}.csv\""
  str = obj.respond_to?(:to_csv) ? obj.to_csv : obj.to_s
  send_data str, type: Mime[:csv], disposition: disposition
end
