# frozen_string_literal: true

# == Schema Information
#
# Table name: form_templates
#
#  id          :uuid             not null, primary key
#  name        :string(255)      not null
#  description :text
#  category    :string(255)
#  tags        :string(255)      is an Array
#  template_data :jsonb
#  is_public   :boolean          default(FALSE), not null
#  usage_count :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  creator_id  :uuid             not null
#  mission_id  :uuid
#
# Indexes
#
#  index_form_templates_on_creator_id  (creator_id)
#  index_form_templates_on_mission_id  (mission_id)
#  index_form_templates_on_category    (category)
#  index_form_templates_on_is_public   (is_public)
#  index_form_templates_on_usage_count (usage_count)
#
# Foreign Keys
#
#  form_templates_creator_id_fkey  (creator_id => users.id) ON DELETE => restrict
#  form_templates_mission_id_fkey  (mission_id => missions.id) ON DELETE => cascade
#

class FormTemplate < ApplicationRecord
  include MissionBased

  belongs_to :creator, class_name: "User"
  belongs_to :mission, optional: true

  validates :name, presence: true
  validates :template_data, presence: true

  scope :public_templates, -> { where(is_public: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :popular, -> { order(usage_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) { where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") }

  CATEGORIES = %w[
    survey
    assessment
    evaluation
    registration
    feedback
    inspection
    monitoring
    data_collection
    other
  ].freeze

  validates :category, inclusion: {in: CATEGORIES}, allow_blank: true

  def self.create_from_form(form, creator, name: nil, description: nil, category: nil, tags: [], is_public: false)
    template_data = {
      form_name: form.name,
      questions: form.questions.map do |question|
        {
          id: question.id,
          code: question.code,
          name: question.name,
          type: question.qtype_name,
          required: question.required?,
          options: question.option_set&.options&.map { |opt| {id: opt.id, name: opt.name} },
          conditions: question.conditions.map do |condition|
            {
              id: condition.id,
              ref_qing_id: condition.ref_qing_id,
              op: condition.op,
              value: condition.value
            }
          end
        }
      end,
      form_settings: {
        allow_incomplete: form.allow_incomplete,
        authenticate_sms: form.authenticate_sms,
        smsable: form.smsable,
        sms_relay: form.sms_relay
      }
    }

    create!(
      name: name || form.name,
      description: description,
      category: category,
      tags: tags,
      template_data: template_data,
      is_public: is_public,
      creator: creator,
      mission: creator.current_mission
    )
  end

  def create_form_from_template(mission, _creator, form_name: nil)
    form = Form.create!(
      name: form_name || name,
      mission: mission,
      allow_incomplete: template_data.dig("form_settings", "allow_incomplete") || false,
      authenticate_sms: template_data.dig("form_settings", "authenticate_sms") || true,
      smsable: template_data.dig("form_settings", "smsable") || false,
      sms_relay: template_data.dig("form_settings", "sms_relay") || false
    )

    # Create questions from template
    template_data["questions"]&.each do |question_data|
      question = Question.create!(
        code: question_data["code"],
        name: question_data["name"],
        qtype_name: question_data["type"],
        required: question_data["required"] || false,
        mission: mission
      )

      # Create option set if needed
      if question_data["options"].present?
        option_set = OptionSet.create!(
          name: "#{question.name} Options",
          mission: mission
        )

        question_data["options"].each do |option_data|
          Option.create!(
            name: option_data["name"],
            option_set: option_set,
            mission: mission
          )
        end

        question.update!(option_set: option_set)
      end

      # Create questionings
      Questioning.create!(
        form: form,
        question: question,
        mission: mission
      )
    end

    # Increment usage count
    increment!(:usage_count)

    form
  end

  def preview_data
    {
      name: name,
      description: description,
      category: category,
      tags: tags,
      question_count: template_data.dig("questions")&.length || 0,
      created_at: created_at,
      creator: creator.name,
      usage_count: usage_count
    }
  end

  def can_be_used_by?(user)
    return true if is_public?
    return true if mission.present? && user.missions.include?(mission)
    return true if creator == user
    false
  end
end
