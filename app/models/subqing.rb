# For a select questioning with a multilevel option set, represents one level of the questioning.
# For all other questionings, just an alias.
class Subqing
  attr_accessor :questioning, :level, :rank

  def initialize(attribs = {})
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
  end

  # Returns the odk code for the question. If options[:previous] is true,
  # returns the code for the immediately previous subqing (multilevel only).
  def odk_code(options = {})
    base = Odk::DecoratorFactory.decorate(questioning).odk_code
    if multilevel?
      r = options[:previous] ? rank - 1 : rank
      "#{base}_#{r}"
    else
      base
    end
  end

  def name(*args)
    base = questioning.send(:name, *args)
    multilevel? ? "#{base} - #{level.name}" : base
  end

  # Whether this Subqing is the first in its set (i.e. rank is nil or 1)
  def first_rank?
    rank.nil? || rank == 1
  end

  def method_missing(*args)
    questioning.send(*args)
  end
end
