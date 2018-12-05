# fronzen_string_literal: true

shared_context "load_testing" do
  def without_timestamps(content)
    content.gsub(/^.+start_time.+$/, "").gsub(/^.+end_time.+$/, "")
  end
end
