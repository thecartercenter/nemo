# Gets option suggestions based on a query.
class OptionSuggester

  MAX_SUGGESTIONS = 5 # The max number of suggestion matches to return

  # Returns an array of Options matching the given mission and textual query.
  def suggest(mission, query)

    # Trim query to maximum length.
    query = query[0...Option::MAX_NAME_LENGTH]

    name_clause = sanitize("name_translations RLIKE ?", "%%%1#{query}%%%2").tap do |sql|
      sql.gsub!('%%%1', %{"#{I18n.locale}":"})
      sql.gsub!('%%%2', %{([^"\\]|\\\\\\\\.)*"})
    end

    matches = Option.where(mission_id: mission.try(:id)).where(name_clause).to_a

    # Sort exact matches to top.
    exact_match = false
    matches.sort_by! do |match|
      # If an exact match, set a flag and put it at the top
      if match.name =~ /\A#{Regexp.escape(query)}\z/i
        exact_match = true
        [0,match.name]
      else
        [1,match.name]
      end
    end

    # Trim results to max size (couldn't do this earlier b/c had to search whole list for exact match)
    matches = matches[0...MAX_SUGGESTIONS]

    # if there was no exact match, we append a 'new option' placeholder
    matches << Option.new(:name => query) unless exact_match

    matches
  end

  def sanitize(*args)
    ActiveRecord::Base.__send__(:sanitize_sql, args, '')
  end
end