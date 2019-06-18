# frozen_string_literal: true

class Array
  # Matches elements of a to elements of b and passes each pair to a block.
  # If an element of a has no match in b or vice versa, nil is passed.
  # Assumes no duplicates in either array.
  def compare_by_element(arr, hashfunc = nil)
    hashfunc ||= proc { |x| x }

    # create hashes from a and b. can have multiple elements per key
    ah = {}; each { |x| key = hashfunc.call(x); (ah[key] ||= []) << x }
    bh = {}; arr.each { |x| key = hashfunc.call(x); (bh[key] ||= []) << x }

    # matches: loop over a's elements, find them in b, yield, remove from both hashes
    each do |x|
      key = hashfunc.call(x)
      next unless (hit = bh[key]) && !hit.empty?
      yield(x, hit.first)
      ah[key].shift
      bh[key].shift
    end

    # a-only's: loop over ah's remaining elements. these had no match in b.
    ah.values.flatten.each { |x| yield(x, nil) }

    # b-only's: loop over bh's remaining elements. these had no match in a.
    bh.values.flatten.each { |x| yield(nil, x) }

    nil
  end

  # sorts the array elements by e.rank (or other field name as specified),
  # then assigns contiguous integers to e.rank (1,2,3,4,...)
  # assumes there are less than a billion elements
  def ensure_contiguous_ranks(_field_name = "rank")
    sort_by! { |e| e.rank || 1_000_000_000 }
    each_with_index { |e, idx| e.rank = idx + 1 }
  end

  def map_hash
    Hash[*flat_map { |x| [x, yield(x)] }]
  end

  # Sorts a list of hashes by item key.
  def sort_by_key(key = :name)
    sort do |x, y|
      x_value = x[key]
      y_value = y[key]
      x_value <=> y_value
    end
  end
end
