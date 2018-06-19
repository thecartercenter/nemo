require 'mission_based'
class Report::Report < ApplicationRecord
  include MissionBased

  acts_as_paranoid

  has_many :option_set_choices, class_name: "Report::OptionSetChoice", foreign_key: "report_report_id", inverse_of: :report,
    dependent: :destroy, autosave: true
  has_many :option_sets, through: :option_set_choices
  has_many :calculations, -> { order("rank") }, class_name: "Report::Calculation", foreign_key: "report_report_id", inverse_of: :report,
     dependent: :destroy, autosave: true
  belongs_to :creator, class_name: "User"

  accepts_nested_attributes_for :calculations, allow_destroy: true
  accepts_nested_attributes_for :option_set_choices, allow_destroy: true

  validates :mission, presence: true

  scope :by_viewed_at, -> { order("viewed_at desc") }
  scope :by_popularity, -> { order("view_count desc") }
  scope :by_name, -> { order("name") }

  before_save :normalize_attribs

  attr_accessor :just_created, :populated
  alias_method :populated?, :populated

  # this is overridden by StandardFormReport, and ignored elsewhere
  attr_accessor :disagg_question_id

  # validation is all handled client-side

  @@per_page = 20

  PERCENT_TYPES = %w(none overall by_row by_col)

  # list of all immediate subclasses in the order they should be shown to the user
  SUBCLASSES = %w(Report::TallyReport Report::ListReport Report::StandardFormReport)

  # HACK TO GET STI TO WORK WITH ACCEPTS_NESTED_ATTRIBUTES_FOR
  class << self
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and (klass = type.constantize) != self
        raise "wtF hax!!"  unless klass < self  # klass should be a descendant of us
        return klass.new(*a, &b)
      end

      new_without_cast(*a, &b)
    end
  end

  # remove report sub-relationship of objects
  def self.terminate_sub_relationships(report_ids)
    Report::Calculation.where(report_report_id: report_ids).delete_all
    Report::OptionSetChoice.where(report_report_id: report_ids).delete_all
  end

  def cache_key
    chunks = [super]
    chunks << option_set_choices.map(&:option_set_id)
    chunks << "calcs-#{calculations.count}-"
    chunks << (calculations.reorder(updated_at: :desc).first.try(:cache_key) || "none")
    chunks.join("/")
  end

  # generates a default name that won't collide with any existing names
  def generate_default_name
    prefix = "New Report"

    # get next number
    nums = self.class.for_mission(mission).where("name LIKE '#{prefix}%'").collect do |r|
      # get suffix
      if r.name.match(/^#{prefix}(\s+\d+$|$)/)
        [$1.to_i, 1].max # must be at least one if found
      else
        1
      end
    end
    next_num = (nums.compact.max || 0) + 1
    suffix = next_num == 1 ? "" : " #{next_num}"

    # set to attrib
    self.name = "#{prefix}#{suffix}"
  end

  # Should be overridden by children.
  def run(current_ability = nil, _options = {})
    raise NotImplementedError
  end

  # records a viewing of the form, keeping the view_count up to date
  # It's using the update_column to avoid it updating the updated_at
  # value (which would invalidate the cache). It also skips validations.
  def record_viewing
    update_column(:viewed_at, Time.now)
    update_column(:view_count, self.view_count += 1)
  end

  def as_json(options = {})
    h = super(options)
    h[:new_record] = new_record?
    h[:just_created] = just_created
    h[:type] = type
    h[:filter] = filter
    h[:empty] = empty?
    h[:populated] = populated?
    h
  end

  # should be overridden
  def empty?
    true
  end

  # should be overridden
  def exportable?
    false
  end

  private

  def normalize_attribs
    # we now do default values here as well as changing blanks to nils.
    # the AR default stuff doesn't work b/c the blank from the client side overwrites the default and there's no easy way to get it back
    self.bar_style = "side_by_side" if bar_style.blank?
    self.display_type = "table" if display_type.blank?
    self.percent_type = "none" if percent_type.blank?
    self.text_responses = nil if text_responses.blank?
  end
end
