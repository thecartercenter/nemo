class Report::ResponseCountReport < Report::Report
  def run
    @rel = Response.unscoped
    
    # add groupings
    groupings.each{|g| @rel = g.apply(@rel)}
    
    # add count
    @rel = @rel.select("COUNT(responses.id) as `Count`")
    
    # apply filter
    @rel = filter.apply(@rel) unless filter.nil?
    
    # get data and headers
    results = @rel.all
    if groupings.empty?
      @headers = {:row => [], :col => []}
      @data = [results.first.attributes.values]
    else
      @headers = {
        :row => results.collect{|row| row[pri_grouping.col_name]}.uniq,
        :col => sec_grouping ? results.collect{|row| row[sec_grouping.col_name]}.uniq : ["Count"]
      }
      # create blank data table
      @data = @headers[:row].collect{|r| Array.new(@headers[:col].size)}

      # populate data table
      results.each do |row|
        r = @headers[:row].index(row[pri_grouping.col_name])
        c = sec_grouping ? @headers[:col].index(row[sec_grouping.col_name]) : 0
        @data[r][c] = row["Count"]
      end
    end
  end
end