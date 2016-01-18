Paperclip::Attachment.default_options.merge!(
  path: ':rails_root/uploads/:class/:attachment/:id_partition/:style/:filename',
  url: '/uploads/:class/:id/:style'
)
