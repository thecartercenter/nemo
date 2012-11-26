# models the two headers (row, col) for a given report
class Report::HeaderSet
  attr_reader :headers
  
  # constructs a header_set object with the given row and col sources
  def initialize(headers)
    @headers = headers
  end
  
  # pass the [] operator on to the @headers array
  def [](which)
    @headers[which]
  end
  
  # looks up the row and column indices for the given row and col header keys
  # raises an error if no match is found
  def find_indices(keys)
    [:row, :col].collect do |which|
      @headers[which].find_key_idx(keys[which]) or raise Report::ReportError.new("Couldn't find matching #{which} header key for '#{keys[which]}'")
    end 
  end
end