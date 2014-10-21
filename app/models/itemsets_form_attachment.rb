# Models the itemsets CSV file that is used by ODK to store option sets.
require 'fileutils'
require 'csv'
require 'digest'
include LanguageHelper

class ItemsetsFormAttachment
  attr_accessor :form

  def initialize(attribs)
    self.form = attribs[:form]
  end

  def path
    stamp = (form.published? ? form.pub_changed_at : Time.now).utc.strftime('%Y%m%d_%H%M%S')
    File.join(dir, "itemsets-#{stamp}.csv")
  end

  def md5
    (contents = file_contents) ? Digest::MD5.hexdigest(contents) : (raise IOError.new('file not yet generated'))
  end

  # Ensures the file exists. Generates if not.
  def ensure_generated
    generate! if !form.option_sets.empty? && !File.exists?(priv_path)
  end

  private

    def dir
      File.join('form-attachments', Rails.env, form.id.to_s.rjust(6,'0'))
    end

    def priv_dir
      File.join(Rails.root, 'public', dir)
    end

    def priv_path
      File.join(Rails.root, 'public', path)
    end

    def file_contents
      File.exists?(priv_path) ? File.read(priv_path) : nil
    end

    # Generates the data and saves to file.
    def generate!
      # Create dir if not exist and clear out old itemsets.
      FileUtils.mkdir_p(priv_dir)
      Dir[File.join(priv_dir, 'itemsets-*.csv')].each{ |f| File.unlink(f) }

      CSV.open(priv_path, 'wb') do |csv|
        width = generate_header_row(csv)
        parent_ref_offset = 0 # Need to maintain this as we go so we know which column to start writing parent references.
        form.option_sets.each do |os|
          generate_subtree(os.arrange_with_options, [], csv, parent_ref_offset, width)
          parent_ref_offset += os.level_count - 1 if os.multi_level?
        end
      end
    end

    # Generates CSV header. Returns number of columns.
    def generate_header_row(csv)
      row = ['list_name','name']
      row += configatron.preferred_locales.map{ |l| "label::#{language_name(l)}" }

      form.option_sets.select(&:multi_level?).each do |os|
        # We need to add codes for the first N-1 option levels, of the form osM_levN where M is the option set ID.
        row += (1...os.level_count).to_a.map{ |n| "os#{os.id}_lev#{n}" }
      end
      csv << row
      row.size
    end

    def generate_subtree(subtree, ancestors, csv, parent_ref_offset, total_width)
      subtree.each do |node, children|
        unless node.is_root?
          row = ["os#{node.option_set_id}", "o#{node.option_id}"]
          row += configatron.preferred_locales.map{ |l| node.option.name(l) }
          row += [nil] * parent_ref_offset
          row += ancestors.map{ |n| "o#{n.option_id}" } # Parent references
          row += [nil] * (total_width - row.size)
          csv << row
        end

        generate_subtree(children, ancestors + [node], csv, parent_ref_offset, total_width) unless children.empty?
      end
    end
  end
