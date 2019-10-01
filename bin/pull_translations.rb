#!/usr/bin/env ruby

# Pull translations
`tx pull --all`

# Make the language codes match what is in Rails already.
LANG_CODE_TRANSFORMATIONS = {
  "pt_PT" => "pt",
  "pt_BR" => "pt-BR",
  "ar_EG" => "ar"
}
LANG_CODE_TRANSFORMATIONS.each do |before, after|
  path = "config/locales/#{before}.yml"
  fixed = File.read(path).sub(/\A#{before}:/, "#{after}:")
  File.open(path, "w") { |f| f.write(fixed) }
end
