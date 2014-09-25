require 'rspec/expectations'

RSpec::Matchers.define :end_with do |expected|
  match do |actual|
    actual[-expected.size..-1] == expected
  end
end

RSpec::Matchers.define :be_destroyed do
  match do |actual|
    raise 'expected nil to not be destroyed' if actual.nil?
    !actual.class.exists?(actual.id)
  end
end