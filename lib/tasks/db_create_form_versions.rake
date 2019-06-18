# frozen_string_literal: true

namespace :db do
  desc "Generate form versions for existing forms."
  task create_form_versions: :environment do
    Form.all.each { |f| f.upgrade_version! unless f.current_version }
  end
end
