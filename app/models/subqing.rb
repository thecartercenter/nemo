# For a select questioning with a multilevel option set, represents one level of the questioning.
# For all other questionings, just an alias.
class Subqing
  attr_accessor :questioning, :level, :rank

  def initialize(attribs = {})
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
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
