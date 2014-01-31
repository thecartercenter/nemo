ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

# methods for testing sphinx indexing
class ActiveSupport::TestCase

  def do_sphinx_index
    ThinkingSphinx::Test.index
    # Wait for Sphinx to finish loading in the new index files.
    sleep 0.25 until sphinx_index_finished?
  end

  def sphinx_index_finished?
    Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}.*')].empty?
  end
end