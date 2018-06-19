class Tag < ApplicationRecord
  include MissionBased, Comparable

  acts_as_paranoid

  belongs_to :mission
  has_many :taggings, dependent: :destroy
  has_many :questions, through: :taggings

  before_save { |tag| tag.name.downcase! }

  MAX_SUGGESTIONS = 5 # The max number of suggestion matches to return
  MAX_NAME_LENGTH = 64

  # Returns an array of Tags matching the given mission and textual query.
  def self.suggestions(mission, query)
    tags = Tag.for_mission(mission)

    # Trim query to maximum length.
    query = query[0...MAX_NAME_LENGTH]

    exact_match = tags.find_by_name(query)
    matches = tags.where('name like ?', "%#{query}%").order(:name).limit(MAX_SUGGESTIONS).to_a

    if exact_match
      # if there was an exact match, put it at the top
      matches.unshift(exact_match).uniq!
    else
      # if there was no exact match, we append a 'new tag' placeholder
      matches << Tag.new(name: query)
    end

    matches
  end

  # Tags that should show at the top of question index page
  def self.mission_tags(mission)
    # In admin mode, return all standard tags
    if mission.nil?
      return where(mission_id: nil).order(:name)
    end

    # In mission, show all tags for mission
    question_ids = Question.for_mission(mission).pluck(:id)
    mission_id = mission.try(:id) || 'null'
    includes(:taggings).where(mission_id: mission_id).order(:name)
  end

  # Sorting
  def <=> (other_tag)
    name <=> other_tag.name
  end

  def as_json(options = {})
    super(only: [:id, :name])
  end

end
