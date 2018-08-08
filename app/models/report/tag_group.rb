# A group of TypeGroups containing summaries associated with a particular question tag
class Report::TagGroup
  # if not grouped by tag, should return one big group with tag: nil
  attr_reader :tag, :type_groups

  def self.generate(summaries, options)
    if options[:group_by_tag]
      tag_groups = Hash.new { |h,k| h[k] = [] } # Accessing uninitialized key creates empty array
      untagged = []
      summaries.each do |summary, q = summary.questioning|
        if q.tags.empty?
          untagged << summary
        else
          q.tags.each { |t| tag_groups[t] << summary }
        end
      end

      # Sort by key (tag) and put untagged at the end
      tag_groups = Hash[tag_groups.sort_by { |k, _| k.name }]
      tag_groups[:untagged] = untagged

      tag_groups.map do |tag, sums|
        # Generate type groups for this tag group
        type_groups = Report::TypeGroup.generate(sums, options)
        # Create TagGroup object in array
        new(tag: tag, type_groups: type_groups)
      end
    else
      # return one big tag group
      [new(tag: nil, type_groups: Report::TypeGroup.generate(summaries, options))]
    end
  end

  def initialize(attribs)
    # save attribs
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def as_json(options = {})
    {
      tag: tag,
      type_groups: type_groups
    }
  end
end
