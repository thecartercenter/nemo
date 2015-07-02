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

  # Ensures the file exists if appropriate. Generates if not.
  def ensure_generated
    generate! if !File.exists?(priv_path)
  end

  # True if there is nothing to put in the file.
  # If true, the file will not be generated, even if ensure_generated is called.
  def empty?
    form.option_sets.empty?
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
      return if empty?

      # Create dir if not exist and clear out old itemsets.
      FileUtils.mkdir_p(priv_dir)
      Dir[File.join(priv_dir, 'itemsets-*.csv')].each{ |f| File.unlink(f) }

      CSV.open(priv_path, 'wb') do |csv|
        generate_header_row(csv)
        form.option_sets.each do |os|
          generate_subtree(os.arrange_with_options, csv, os.max_depth)
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

    def generate_subtree(subtree, csv, max_depth, depth = 0)
      subtree.each do |node, children|
        csv << option_row(node) unless node.is_root?

        # If no kids, we must add [None](s) if we are not yet at max depth.
        if children.empty?
          csv << none_row(node, type: :child) if depth + 1 < max_depth
          csv << none_row(node, type: :grandchild) if depth + 1 < max_depth - 1
        else
          generate_subtree(children, csv, max_depth, depth + 1) unless children.empty?
        end
      end
    end

    # Generates a CSV row for a normal node.
    def option_row(node)
      row = ["os#{node.option_set_id}", node.odk_code]
      row += configatron.preferred_locales.map{ |l| node.option.name(l) } # Names
      row << (node.depth > 1 ? node.parent_odk_code : nil) # Node ID and parent node ID (unless parent is root)
      row
    end

    # Generates a 'none' CSV row for uneven option sets.
    # options[:type] - Whether this is a child or (great)grandchild of the last non-None node.
    def none_row(node, options)
      row = ["os#{node.option_set_id}", 'none']
      row += configatron.preferred_locales.map{ |l| "[#{I18n.t('common.blank', locale: l)}]" }
      row << (options[:type] == :child ? node.odk_code : 'none')
      row
    end
  end
