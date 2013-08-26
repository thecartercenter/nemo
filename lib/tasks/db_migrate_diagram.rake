# Builds the diagram pdf after db:migrate is called
Rake::Task['db:migrate'].enhance do
	# Don't show all the attributes for a cleaner presentation
	ENV['attributes'] = 'false'
	# Save to the docs dir
	ENV['filename'] = "#{Rails.root}/docs/erd"
  Rake::Task['erd'].invoke
end