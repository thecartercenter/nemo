class AddFullIndexForAnswers < ActiveRecord::Migration[4.2]
  def up
    # Remove previous indices
    begin
      remove_index :answers, [:response_id, :questioning_id, :rank]
    rescue
      puts "****** Error `#{$!}` when removing previous answers index, may not be a problem"
    end

    add_index :answers, [:response_id, :questioning_id, :inst_num, :rank], name: "answers_full", unique: true
  end
end
