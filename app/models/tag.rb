class Tag < ActiveRecord::Base
  include MissionBased

  belongs_to :mission
  has_many :taggings, dependent: :destroy
  has_many :questions, through: :taggings
  attr_accessible :is_standard, :name, :standard_id

  before_save { |tag| tag.name.downcase! }
  after_save(:invalidate_cache)
  after_destroy(:invalidate_cache)

  MAX_SUGGESTIONS = 5 # The max number of suggestion matches to return
  MAX_NAME_LENGTH = 64

  # Returns an array of Tags matching the given mission and textual query.
  def self.suggestions(mission, query)
    # fetch all mission tags from the cache
    mission_id = mission ? mission.id : 'std'
    tags = Rails.cache.fetch("mission_tags/#{mission_id}", :expires_in => 2.minutes) do
      Tag.unscoped.for_mission(mission)
    end

    # Trim query to maximum length.
    query = query[0...MAX_NAME_LENGTH]

    # where("name like ?", "%#{params[:q]}%").select([:id, :name])

    # scan for tags matching query
    matches = []; exact_match = false
    for i in 0...tags.size
      # if an exact match, set a flag and put it at the top
      if tags[i].name == query
        matches.unshift tags[i]
        exact_match = true
        # otherwise if partial match just insert at the end
      elsif tags[i].name && tags[i].name =~ /#{Regexp.escape(query)}/i
        matches << tags[i]
      end
    end

    # trim results to max size (couldn't do this earlier b/c had to search whole list for exact match)
    matches = matches[0...MAX_SUGGESTIONS]

    # if there was no exact match, we append a 'new tag' placeholder
    unless exact_match
      matches << Tag.new(:name => query)
    end

    matches
  end

  private

    # invalidate the mission tag cache after save, destroy
    def invalidate_cache
      Rails.cache.delete("mission_tags/#{mission_id}")
    end
end
