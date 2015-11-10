delta = Rails.env.production? ? ThinkingSphinx::Deltas::DelayedDelta : true

ThinkingSphinx::Index.define :answer, :with => :active_record, :delta => delta do
  # fields
  indexes value
  indexes option(:canonical_name), as: :option_name
  indexes choices.option.canonical_name, as: :option_names

  # attributes
  has response_id, created_at, updated_at, response.mission_id, questioning.question_id
end
