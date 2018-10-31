#!/usr/bin/env ruby

# Aggregate all english translations into one file
File.open("tmp/combined.en.yml", "w") do |out|
  out.write("en:\n")
  Dir["config/locales/en/*.yml"].each do |path|
    contents = File.read(path)
    out.write(contents.sub(/(.*\n|^)en:\n/m, "")) # Strip the en: line and anything before it.
  end
end

# Run transifex
`tx push -s`
