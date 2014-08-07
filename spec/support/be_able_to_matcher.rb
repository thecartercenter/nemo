# This is the same as the matcher provided by CanCan but updated for RSpec 3's method names
RSpec::Matchers.define :be_able_to do |*args|
  match do |ability|
    ability.can?(*args)
  end

  failure_message do |ability|
    "expected to be able to #{args.map(&:inspect).join(" ")}"
  end

  failure_message_when_negated do |ability|
    "expected not to be able to #{args.map(&:inspect).join(" ")}"
  end
end
