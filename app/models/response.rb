# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: responses
#
#  id                   :uuid             not null, primary key
#  cached_json          :jsonb
#  checked_out_at       :datetime
#  dirty_json           :boolean          default(TRUE), not null
#  incomplete           :boolean          default(FALSE), not null
#  odk_hash             :string(255)
#  odk_xml              :text
#  odk_xml_content_type :string
#  odk_xml_file_name    :string
#  odk_xml_file_size    :bigint
#  odk_xml_updated_at   :datetime
#  reviewed             :boolean          default(FALSE), not null
#  reviewer_notes       :text
#  shortcode            :string(255)      not null
#  source               :string(255)      not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  checked_out_by_id    :uuid
#  device_id            :string
#  form_id              :uuid             not null
#  mission_id           :uuid             not null
#  old_id               :integer
#  reviewer_id          :uuid
#  user_id              :uuid             not null
#
# Indexes
#
#  index_responses_on_checked_out_at        (checked_out_at)
#  index_responses_on_checked_out_by_id     (checked_out_by_id)
#  index_responses_on_created_at            (created_at)
#  index_responses_on_form_id               (form_id)
#  index_responses_on_form_id_and_odk_hash  (form_id,odk_hash) UNIQUE
#  index_responses_on_mission_id            (mission_id)
#  index_responses_on_reviewed              (reviewed)
#  index_responses_on_reviewer_id           (reviewer_id)
#  index_responses_on_shortcode             (shortcode) UNIQUE
#  index_responses_on_updated_at            (updated_at)
#  index_responses_on_user_id               (user_id)
#  index_responses_on_user_id_and_form_id   (user_id,form_id)
#
# Foreign Keys
#
#  responses_checked_out_by_id_fkey  (checked_out_by_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_form_id_fkey            (form_id => forms.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_mission_id_fkey         (mission_id => missions.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_reviewer_id_fkey        (reviewer_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#  responses_user_id_fkey            (user_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

class Response < ApplicationRecord
  extend FriendlyId
  include MissionBased
  include Cacheable
  include Wisper.model

  LOCK_OUT_TIME = 10.minutes
  CODE_CHARS = ("a".."z").to_a + ("0".."9").to_a
  CODE_LENGTH = 5

  attr_accessor :modifier, :awaiting_media

  belongs_to :form, inverse_of: :responses
  belongs_to :checked_out_by, class_name: "User"
  belongs_to :user, inverse_of: :responses
  belongs_to :reviewer, class_name: "User"

  has_many :answers, -> { order(:new_rank) },
    autosave: true, dependent: :destroy, inverse_of: :response

  # This association used only for cloning, hence it being private.
  has_many :response_nodes # rubocop:disable Rails/HasManyOrHasOneDependent
  private :response_nodes, :response_nodes=

  has_closure_tree_root :root_node, class_name: "ResponseNode"

  has_one_attached :odk_xml
  validates :odk_xml, content_type: %r{\A(text|application)/xml\z}

  friendly_id :shortcode

  before_validation :normalize_reviewed

  after_update { root_node.save if root_node.present? }
  before_create :generate_shortcode
  before_destroy { root_node.destroy if root_node.present? }

  # we turn off validate above and do it here so we can control the message and have only one message
  # regardless of how many answer errors there are
  validates :user, presence: true
  validate :form_in_mission
  validates_associated :answers # Forces validation of answers even if they haven't changed
  validates_associated :root_node

  scope :unreviewed, -> { where(reviewed: false) }
  scope :by, ->(user) { where(user_id: user.id) }
  scope :created_after, ->(date) { where("responses.created_at >= ?", date) }
  scope :created_before, ->(date) { where("responses.created_at <= ?", date) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :dirty, -> { where(dirty_json: true) }
  scope :published, -> { joins(:form).merge(Form.published) }

  # loads basic belongs_to associations
  scope :with_basic_assoc, -> { includes(:form, :user) }

  # loads only some answer info
  scope :with_basic_answers, -> { includes(answers: {form_item: :question}) }

  delegate :name, to: :checked_out_by, prefix: true
  delegate :questionings, to: :form
  delegate :c, :children, :debug_tree, :matching_group_set, to: :root_node

  clone_options follow: %i[response_nodes form user reviewer]

  # remove previous checkouts by a user
  def self.remove_previous_checkouts_by(user = nil)
    raise ArgumentError, "A user is required" unless user

    Response.where(checked_out_by_id: user).update_all(checked_out_at: nil, checked_out_by_id: nil)
  end

  # returns a count how many responses have arrived recently
  # format e.g. [5, "week"] (5 in the last week)
  # nil means no recent responses
  def self.recent_count(rel)
    %w[hour day week month year].each do |p|
      if (count = rel.where("created_at > ?", 1.send(p).ago).count).positive?
        return [count, p]
      end
    end
    nil
  end

  # returns an array of N response counts grouped by form
  # uses the WHERE clause from the given relation
  def self.per_form(rel, n)
    where_clause = rel.to_sql.match(/WHERE (.+?)(ORDER BY|\z)/)[1]

    find_by_sql("
      SELECT forms.name AS form_name, COUNT(responses.id) AS count
      FROM responses INNER JOIN forms ON responses.form_id = forms.id
      WHERE #{where_clause}
      GROUP BY forms.id, forms.name
      ORDER BY count DESC
      LIMIT #{n}")
  end

  # generates a cache key for the set of all responses for the given mission.
  # the key will change if the number of responses changes, or if a response is updated.
  def self.per_mission_cache_key(mission)
    count_and_date_cache_key(rel: for_mission(mission), prefix: "mission-#{mission.id}")
  end

  def self.terminate_sub_relationships(response_ids)
    answer_ids = Answer.where(response_id: response_ids).pluck(:id)
    Choice.where(answer_id: answer_ids).delete_all
    Media::Object.where(answer_id: answer_ids).delete_all
    ResponseNode.where(response_id: response_ids).delete_all
  end

  # We need a name field so that this class matches the Nameable duck type.
  def name
    "##{id}"
  end

  # whether the answers should validate themselves
  def validate_answers?
    # ODK and SMS do their own validation
    %w[odk web].include?(modifier)
  end

  def check_out_valid?
    checked_out_at > Response::LOCK_OUT_TIME.ago
  end

  def checked_out_by_others?(user = nil)
    raise ArgumentError, "A user is required" unless user

    !checked_out_by.nil? && checked_out_by != user && check_out_valid?
  end

  def check_out!(user = nil)
    raise ArgumentError, "A user is required to checkout a response" unless user

    unless checked_out_by_others?(user)
      transaction do
        Response.remove_previous_checkouts_by(user)

        self.checked_out_at = Time.zone.now
        self.checked_out_by = user
        save(validate: false)
      end
    end
  end

  def check_in
    self.checked_out_at = nil
    self.checked_out_by_id = nil
  end

  def check_in!
    check_in
    save!
  end

  def generate_shortcode
    loop do
      response_code = CODE_LENGTH.times.map { CODE_CHARS.sample }.join
      mission_code = mission.shortcode
      # form code should never be nil, because one is generated on publish
      # but we are falling back to "000" just in case something goes wrong
      form_code = form.code || "000"

      self.shortcode = [mission_code, form_code, response_code].join("-")
      break unless Response.exists?(shortcode: shortcode)
    end
  end

  private

  def normalize_reviewed
    self.reviewed = true if reviewer_id.present? || reviewer_notes.present?
  end

  def form_in_mission
    errors.add(:form, :form_unavailable) unless mission.forms.include?(form)
  end
end
