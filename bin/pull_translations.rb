#!/usr/bin/env ruby

# Pull translations
`tx pull --all`

# Remove suffixes like _EG from ar_EG in translation files.
Dir["config/locales/*.yml"].select { |f| f.index("_") }.each do |path|
  fixed = File.read(path).sub(/\A([a-z]+)_[A-Z]+:/, "\\1:")
  File.open(path, "w") { |f| f.write(fixed) }
end
