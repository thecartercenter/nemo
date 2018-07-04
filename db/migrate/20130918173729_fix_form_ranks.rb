class FixFormRanks < ActiveRecord::Migration[4.2]
  def up
    Form.all.each do |f|
      if f.respond_to?(:fix_ranks)
        puts "checking form '#{f.name}'"

        # save ranks before adjustment
        before = f.questionings.map(&:rank)

        # fix
        f.fix_ranks

        # now check if they changed
        after = f.questionings.map(&:rank)

        if after != before
          puts "form '#{f.name}' changed from #{before.join(',')} to #{after.join(',')}"
        end
      else
        puts "form does not have fix_ranks method"
        break
      end
    end
  end

  def down
  end
end
