class RemoveForeignKeyIndices < ActiveRecord::Migration[4.2]
  def up
  	remove_index "answers", ["option_id"]
	  remove_index "answers", ["questioning_id"]
	  remove_index "answers", ["response_id"]
	  remove_index "assignments", ["mission_id"]
	  remove_index "assignments", ["user_id"]
	  remove_index "broadcasts", ["mission_id"]
	  remove_index "choices", ["answer_id"]
	  remove_index "choices", ["option_id"]
	  remove_index "forms", ["mission_id"]
	  remove_index "option_sets", ["mission_id"]
	  remove_index "optionings", ["option_id"]
	  remove_index "optionings", ["option_set_id"]
	  remove_index "options", ["mission_id"]
	  remove_index "questionings", ["form_id"]
	  remove_index "questionings", ["question_id"]
	  remove_index "questions", ["mission_id"]
	  remove_index "questions", ["option_set_id"]
	  remove_index "report_option_set_choices", ["option_set_id"]
	  remove_index "report_option_set_choices", ["report_report_id"]
	  remove_index "responses", ["form_id"]
	  remove_index "responses", ["mission_id"]
	  remove_index "responses", ["user_id"]
	  remove_index "sessions", ["session_id"]
	  remove_index "settings", ["mission_id"]
	end

  def down
  end
end
