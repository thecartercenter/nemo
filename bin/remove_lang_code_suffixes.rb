#!/usr/bin/env ruby
# Removes suffixes like _EG from ar_EG in translation files.
Dir["config/locales/*"].select { |d| File.directory?(d) && File.basename(d).index("_") }.each do |dir|
  Dir[File.join(dir, "*.yml")].each do |path|
    fixed = File.read(path).sub(/\A([a-z]+)_[A-Z]+:/, "\\1:")
    File.open(path, "w") { |f| f.write(fixed) }
  end
end
