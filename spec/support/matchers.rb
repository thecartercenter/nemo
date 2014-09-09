require 'rspec/expectations'

RSpec::Matchers.define :end_with do |expected|
  match do |actual|
    actual[-expected.size..-1] == expected
  end
end
