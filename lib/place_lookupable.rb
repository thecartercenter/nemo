module PlaceLookupable
  attr_accessor :place_lookup_query
  
  def place_suggestion_ids; @place_suggestion_ids ||= ""; end
  def place_suggestions; @place_suggestions ||= []; end

  # sets suggestion_ids AND suggestions
  def place_suggestion_ids=(ids)
    @place_suggestion_ids = ids
    @place_suggestions = ids.split(",").map{|id| Place.find(id)}
  end
  
  # sets suggestions AND suggestion_ids
  def place_suggestions=(sugs)
    @place_suggestions = sugs
    @place_suggestion_ids = sugs.map{|s| s.id}.join(",")
  end
end