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
        generate_header_row(csv)
        form.option_sets.each do |os|
          generate_subtree(os.arrange_with_options, csv)
        end
      end
    end

    # Generates CSV header.
    def generate_header_row(csv)
      row = ['list_name','name']
      row += configatron.preferred_locales.map{ |l| "label::#{language_name(l)}" }
      row += %w(parent_id)
      csv << row
    end

    def generate_subtree(subtree, csv)
      subtree.each do |node, children|
        unless node.is_root?
          row = ["os#{node.option_set_id}", "on#{node.id}"]
          row += configatron.preferred_locales.map{ |l| node.option.name(l) } # Names
          row << (node.depth > 1 ? "on#{node.parent_id}" : nil) # Node ID and parent node ID (unless parent is root)
          csv << row
        end

        generate_subtree(children, csv) unless children.empty?
      end
    end
  end
