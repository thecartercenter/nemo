# Models a path of options through an option set, e.g. U.S.A -> Georgia -> Atlanta.
class OptionPath
  attr_accessor :option_set, :options

  delegate :multi_level?, to: :option_set

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    ensure_options_for_all_levels
  end

  # True if all options are nil.
  def blank?
    options.all?(&:nil?)
  end

  def level_name_for_depth(depth)
    option_set.levels[depth-1].name
  end

  def level_count
    @level_count ||= option_set.level_count || 1
  end

  # Returns the available Options at the given depth (1-based).
  # If depth is > 1 and the option at the previous depth is currently nil, returns [].
  def options_for_depth(depth)
    ids = option_ids_up_to_depth(depth - 1)
    option_set.options_for_node(ids) || []
  end

  def option_ids_with_no_nils
    options.compact.map(&:id)
  end

  private

  def ensure_options_for_all_levels
    self.options ||= []
    level_count.times.each do |i|
      rank = multi_level? ? i + 1 : nil
      options[i] ||= nil
    end
  end

  def option_ids_up_to_depth(depth)
    options[0...depth].map{ |o| o.try(:id) }
  end
end
