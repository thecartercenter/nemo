# Generates unique values during replication.
class Replication::UniqueFieldGenerator
  attr_accessor :klass, :orig_id, :mission_id, :exclude_id, :field, :style

  # attribs[:klass] - The class in question.
  # attribs[:orig_id] - The ID of the object we're copying from.
  # attribs[:mission_id] - The ID of the mission in which it should be unique.
  # attribs[:field] - The field to operate on.
  # attribs[:style] - The style to adhere to in generating the unique value (:sep_words or :camel_case).
  # attribs[:exclude_id] - (optional) An ID of an object to exclude when looking for conflicts.
  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  # ensures the given name or other field would be unique, and generates a new name if it wouldnt be
  # (e.g. My Form 2, My Form 3, etc.) for the given name (e.g. My Form)
  def generate
    # Get existing value
    cur_val = klass.where(id: orig_id).pluck(field).first

    # extract any numeric suffix from existing value
    if style == :sep_words
      prefix = cur_val.gsub(/( \d+)?$/, '')
    else
      prefix = cur_val.gsub(/(\d+)?$/, '')
    end

    # keep track of whether we found the exact name
    found_exact = false

    # build a relation to get existing objs matching prefix
    existing = klass.for_mission_id(mission_id).where(["#{field} LIKE ?", "#{prefix}%"])
    existing = existing.where("id != #{exclude_id}") if exclude_id

    # get the number suffixes of all existing objects
    # e.g. if there are My Form, My Form 4, My Form 3, return [1, 4, 3]
    existing_nums = existing.pluck(field).map do |val|

      # for the current match, check if it's an exact match and take note
      found_exact = true if val.downcase.strip == cur_val.downcase.strip

      # check if the current existing object's name matches the name we're looking for
      number_re = style == :sep_words ? /\s*( (\d+))?/ : /((\d+))?/
      m = val.match(/\A#{Regexp.escape(prefix)}#{number_re}\s*\z/i)

      # if there was no match, return nil (this will be compacted out of the array at the end)
      if m.nil?
        nil
      # else if we got a match then we must examine what matched
      # if it was just the prefix, the number is 1
      elsif $2.nil?
        1
      # otherwise we matched a digit so use that
      else
        $2.to_i
      end
    end.compact

    # if we didn't find the exact match or any prefix matches, then no need to add any new suffix
    # just return the name as is
    return cur_val if existing_nums.empty? || !found_exact

    # copy num is max of existing plus 1
    copy_num = existing_nums.max + 1

    # suffix string depends on style
    if style == :sep_words
      suffix = " #{copy_num}"
    else
      suffix = copy_num.to_s
    end

    # now build the new value and return
    "#{prefix}#{suffix}"
  end
end
