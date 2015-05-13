RSpec.configure do |config|

  config.before(:suite) do
    ThinkingSphinx::Test.init
  end

  config.around(:each, sphinx: true) do |example|
    ThinkingSphinx::Test.run do
      example.run
    end
  end

  config.around(:each, no_sphinx: true) do |example|
    ThinkingSphinx::Deltas.suspend(:answers) do
      example.run
    end
  end
end

module SphinxSupport
  def do_sphinx_index
    ThinkingSphinx::Test.index
    # Wait for Sphinx to finish loading in the new index files.
    sleep 0.25 until sphinx_index_finished?
  end

  def sphinx_index_finished?
    Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}.*')].empty?
  end
end
