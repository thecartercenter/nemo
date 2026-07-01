# frozen_string_literal: true

require "delegate"

# Temporary alias so React on Rails can coexist with react-rails during incremental migration.
module ReactOnRailsMigrationHelper
  class ViewProxy < SimpleDelegator
    include ReactOnRails::Helper
  end

  def react_on_rails_component(component_name, **options)
    ViewProxy.new(self).react_component(component_name, options)
  end
end
