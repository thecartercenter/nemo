# Builds the diagram pdf after db:migrate is called
Rake::Task['db:migrate'].enhance do
  Rake::Task['erd'].invoke('attributes','false')
end