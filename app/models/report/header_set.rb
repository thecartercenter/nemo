class Report::HeaderSet
  attr_reader :headers
  
  # constructs a header_set object with the given row and col sources
  def initialize(results, sources, options = {})
    @sources = sources
    @headers = {}
    [:row, :col].each do |dim| 
      # if source is a number, just make an array of nils the same size as the results
      if !@sources.keys.include?(dim)
        @headers[dim] = Array.new(results.size)
      # otherwise call the headers function on the source
      else
        @headers[dim] = @sources[dim].nil? ? [{:name => options[:default_name], :value => 0}] : @sources[dim].headers(results)
      end
    end
  end
  
  def [](dim)
    @headers[dim]
  end
  
  def find_indices(result_row, result_row_idx, result_col_name = nil)
    if result_col_name.nil?
      r = @sources[:row] ? find(:row, @sources[:row].key(result_row)) : 0
      c = @sources[:col] ? find(:col, @sources[:col].key(result_row)) : 0
    else
      r = result_row_idx
      c = find(:col, result_col_name)
    end
    return [r, c]
  end
  
  def delete(row_or_col, idx)
    @headers[row_or_col].delete_at(idx)
  end
  
  def titles
    Hash[*@sources.collect{|k,s| [k, nn(s).title]}.flatten]
  end
  
  def associated_fieldlet(row_or_col, idx)
    @headers[row_or_col][idx][:fieldlet]
  end
  
  def blank_data_table
    @headers[:row].collect{|h| Array.new(@headers[:col].size)}
  end
  
  def blank_total_hash
    {:row => Array.new(@headers[:row].size, 0), :col => Array.new(@headers[:col].size, 0)}
  end
  
  def to_json
    @headers.to_json
  end
  
  private
    def find(row_or_col, key)
      @headers[row_or_col].index{|h| h[:key] == key}
    end
end