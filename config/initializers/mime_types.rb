# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :xlsx)

# Avoid Paperclip to handle newer office files (docx/xlsx/pptx) as application/zip
# https://github.com/thoughtbot/paperclip/issues/896#issuecomment-538136513
[
  ["application/vnd.openxmlformats-officedocument.presentationml.presentation", [[0..2000, "ppt/"]]],
  ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", [[0..2000, "xl/"]]],
  ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", [[0..2000, "word/"]]]
].each do |magic|
  MimeMagic.add(magic[0], magic: magic[1])
end
