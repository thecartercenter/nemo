# Gets option suggestions based on a query.
class OptionSuggester

  MAX_SUGGESTIONS = 5 # The max number of suggestion matches to return

  # Returns an array of Options matching the given mission and textual query.
  def suggest(mission, query)
    query = query[0...Option::MAX_NAME_LENGTH]
    name_clause = SqlRunner.instance.sanitize(
      "name_translations ->> ? ILIKE ?", configatron.preferred_locale, "#{query}%")
    matches = Option.where(mission_id: mission.try(:id)).where(name_clause).to_a

    # Sort exact matches to top.
    exact_match = false
    matches.sort_by! do |match|
      # If an exact match, set a flag and put it at the top
      if match.name =~ /\A#{Regexp.escape(query)}\z/i
        exact_match = true
        [0, match.name]
      else
        [1, match.name]
      end
    end

    # Trim results to max size (couldn't do this earlier b/c had to search whole list for exact match)
    matches = matches[0...MAX_SUGGESTIONS]

    # if there was no exact match, we append a 'new option' placeholder
    matches << Option.new(:"name_#{configatron.preferred_locale}" => query) unless exact_match

    matches
  end
end
