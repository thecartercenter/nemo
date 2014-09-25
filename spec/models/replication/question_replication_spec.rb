require 'spec_helper'

describe Question do
  context 'when option set copy has been reused' do
    before do
      @std_q = create(:question, qtype_name: 'select_one', is_standard: true)
      @copy_q = @std_q.replicate(mode: :to_mission, dest_mission: get_mission)
      @copy_os = @copy_q.option_set
      @reuser_q = create(:question, qtype_name: 'select_one', option_set: @copy_os)
    end

    context 'on question type change' do
      before do
        @std_q.qtype_name = 'integer'
        @std_q.option_set = nil
        @std_q.save_and_rereplicate
        @copy_q.reload
      end

      it 'should rereplicate change but not destroy option set copy' do
        expect(@copy_q.qtype_name).to eq 'integer'
        expect(@copy_q.option_set).to be_nil
        expect(@copy_os).not_to be_destroyed
      end
    end

    context 'on destroy' do
      before do
        @std_q.destroy_with_copies
      end

      it 'should destroy question copy but not option set copy' do
        expect(@std_q).to be_destroyed
        expect(@copy_os).not_to be_destroyed
      end
    end
  end
end
