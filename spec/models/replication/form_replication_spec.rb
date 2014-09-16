# require 'spec_helper'
#
# describe Form do
#   before(:all) do
#     @mission1 = create(:mission)
#     @mission2 = create(:mission)
#   end
#
#   describe 'to_mission' do
#     before do
#       @std_form = create(:form, question_types: %w(integer integer), is_standard: true)
#       @std_form.questionings[1].condition = create(:condition, ref_qing: @std_form.questionings[0])
#       @std_form.save!
#       @copy = @std_form.replicate(mode: :to_mission, dest_mission: @mission2)
#     end
#
#     context 'on condition destroy' do
#       before do
#         @std_qing = @std_form.questionings[1]
#         @std_qing.condition.destroy
#         @copy_q = @std_q.replicate(mode: :to_mission, dest_mission: get_mission)
#         @copy_os = @copy_q.option_set
#         @reuser_q = create(:question, qtype_name: 'select_one', option_set: @copy_os)
#       end
#
#       context 'on question type change' do
#         before do
#           @std_q.qtype_name = 'integer'
#           @std_q.option_set = nil
#           @std_q.save_and_rereplicate
#           @copy_q.reload
#         end
#
#         it 'should rereplicate change but not destroy option set copy' do
#           expect(@copy_q.qtype_name).to eq 'integer'
#           expect(@copy_q.option_set).to be_nil
#           expect(@copy_os).not_to be_destroyed
#         end
#       end
#
#       context 'on destroy' do
#         before do
#           @std_q.destroy_with_copies
#         end
#
#         it 'should destroy question copy but not option set copy' do
#           expect(@std_q).to be_destroyed
#           expect(@copy_os).not_to be_destroyed
#         end
#       end
#     end
#   end
# end
