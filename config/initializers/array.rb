class Array
  # Matches elements of a to elements of b and passes each pair to a block.
  # If an element of a has no match in b or vice versa, nil is passed.
  # Assumes no duplicates in either array.
  def compare_by_element(arr, hashfunc = nil, &block)
    hashfunc ||= Proc.new{|x| x}

    # create hashes from a and b. can have multiple elements per key
    ah = {}; self.each{|x| key = hashfunc.call(x); (ah[key] ||= []) << x}
    bh = {}; arr.each{|x| key = hashfunc.call(x); (bh[key] ||= []) << x}

    # matches: loop over a's elements, find them in b, yield, remove from both hashes
    self.each do |x|
      key = hashfunc.call(x)
      if hit = bh[key] and !hit.empty?
        block.call(x, hit.first)
        ah[key].shift
        bh[key].shift
      end
    end

    # a-only's: loop over ah's remaining elements. these had no match in b.
    ah.values.flatten.each{|x| block.call(x, nil)}

    # b-only's: loop over bh's remaining elements. these had no match in a.
    bh.values.flatten.each{|x| block.call(nil, x)}

    nil
  end

  # sorts the array elements by e.rank (or other field name as specified),
  # then assigns contiguous integers to e.rank (1,2,3,4,...)
  # assumes there are less than a billion elements
  def ensure_contiguous_ranks(field_name = 'rank')
    sort_by!{|e| e.rank || 1_000_000_000}
    each_with_index{|e, idx| e.rank = idx + 1}
  end

  def map_hash
    Hash[*map{ |x| [x, yield(x)] }.flatten(1)]
  end

  # Sorts a list of hashes by item key, using smart_compare below.
  def smart_sort_by_key(key = :name)
    sort do |x, y|
      x_value = x[key]
      y_value = y[key]
      smart_compare(x_value, y_value)
    end
  end

  private

  # Compares two strings alphabetically, ignoring case, properly understanding
  # numbers at the BEGINNING of the string only (for performance reasons).
  def smart_compare(x_value, y_value)
    pattern = /(\d*)(.*)/
    x_match = x_value.downcase.match(pattern)
    y_match = y_value.downcase.match(pattern)

    # If both start with numbers, compare the numbers first.
    if !x_match[1].empty? && !y_match[1].empty?
      comparison = x_match[1].to_i <=> y_match[1].to_i
      return comparison unless comparison.zero?
      return x_match[2] <=> y_match[2]
    end

    # Otherwise compare the entire string.
    x_match[0] <=> y_match[0]
  end
end
