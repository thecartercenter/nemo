# TODO
class Report::TagGroup
  # if not grouped by tag, should return one big group with tag: nil
  attr_reader :tag, :type_groups

  def self.generate(summaries, options)
    summaries_by_question = summaries.index_by(&:questioning)
    if options[:group_by_tag]
      options[:questions_by_tag].map do |tag, questions|
        # Generate type groups for this tag group
        type_groups = Report::TypeGroup.generate(questions.map { |q| summaries_by_question[q] }, options)
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

end
