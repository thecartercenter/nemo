class Report::ResponseTallyReport < Report::TallyReport

  def as_json(options = {})
    h = super(options)
    h[:calculations_attributes] = calculations
    h
  end

  protected

    def prep_query(rel)
      joins = []

      # add tally to select
      rel = rel.select("COUNT(responses.id) AS tally")

      # add filter
      rel = apply_filter(rel)

      # add groupings
      rel = apply_groupings(rel)
    end

    # applys both groupings
    def apply_groupings(rel, options = {})
      raise Report::ReportError.new("primary groupings not allowed for this report type") if pri_grouping && options[:secondary_only]
      rel = pri_grouping.apply(rel) if pri_grouping
      rel = sec_grouping.apply(rel) if sec_grouping
      return rel
    end

    def has_grouping(which)
      grouping = which == :row ? pri_grouping : sec_grouping
      !grouping.nil?
    end

    def header_title(which)
      grouping = which == :row ? pri_grouping : sec_grouping
      grouping ? grouping.header_title : nil
    end

  private

    def grouping(rank)
      c = calculations.find_by_rank(rank)
      c.nil? ? nil : Report::Grouping.new(c, [:primary, :secondary][rank-1])
    end

    def pri_grouping
      @pri_grouping ||= grouping(1)
    end

    def sec_grouping
      @sec_grouping ||= grouping(2)
    end
end
