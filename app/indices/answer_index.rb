ThinkingSphinx::Index.define :answer, :with => :active_record, :delta => true do
  # fields
  indexes value

  # attributes
  has response_id, created_at, updated_at, response.mission_id, questioning.question_id
end