class Tag < ActiveRecord::Base
  include MissionBased

  belongs_to :mission
  has_many :taggings, dependent: :destroy
  has_many :questions, through: :taggings
  attr_accessible :is_standard, :name, :standard_id, :mission_id

  before_save { |tag| tag.name.downcase! }

  MAX_SUGGESTIONS = 5 # The max number of suggestion matches to return
  MAX_NAME_LENGTH = 64

  # Returns an array of Tags matching the given mission and textual query.
  def self.suggestions(mission, query)
    tags = Tag.for_mission([mission, nil])

    # Trim query to maximum length.
    query = query[0...MAX_NAME_LENGTH]

    exact_match = tags.find_by_name(query)
    matches = tags.where('name like ?', "%#{query}%").order(:name).limit(MAX_SUGGESTIONS)

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
      return where(is_standard: true).order(:name)
    end

    # In mission, show all tags for mission plus standard tags applied to mission
    question_ids = Question.for_mission(mission).pluck(:id)
    mission_id = mission.try(:id) || 'null'
    joins(:taggings).where('mission_id = ? OR (tags.is_standard = true AND taggings.question_id IN (?))',
        mission_id, question_ids).uniq.order(:name)
  end

end
