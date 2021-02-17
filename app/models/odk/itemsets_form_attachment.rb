# frozen_string_literal: true

require "fileutils"
require "digest"

module ODK
  # Models the itemsets CSV file that is used by ODK to store option sets.
  class ItemsetsFormAttachment
    include LanguageHelper
    attr_accessor :form

    delegate :mission_config, to: :form

    def initialize(attribs)
      self.form = attribs[:form]
    end

    # The relative path, including filename, to the attachment.
    def path
      return @path if @path
      stamp = (form.draft? ? Time.current : form.published_changed_at).utc.strftime("%Y%m%d_%H%M%S")
      @path = File.join(dir, "itemsets-#{stamp}.csv")
    end

    def md5
      (contents = file_contents) ? Digest::MD5.hexdigest(contents) : (raise IOError, "file not yet generated")
    end

    # Ensures the file exists if appropriate. Generates if not.
    # Returns self to enable chaining.
    def ensure_generated
      generate! unless File.exist?(priv_path)
      self
    end

    # True if there is nothing to put in the file.
    # If true, the file will not be generated, even if ensure_generated is called.
    def empty?
      !decorated_form.needs_external_csv?
    end

    # The full path to the file.
    def priv_path
      @priv_path ||= Rails.root.join("public", path)
    end

    private

    def decorated_form
      ODK::DecoratorFactory.decorate(form)
    end

    # The subdirectory where the attachment should go.
    def dir
      @dir ||= File.join("form-attachments", Rails.env, form.id.to_s.rjust(6, "0"))
    end

    # The full path to the directory.
    def priv_dir
      @priv_dir ||= Rails.root.join("public", dir)
    end

    def file_contents
      File.exist?(priv_path) ? File.read(priv_path) : nil
    end

    # Generates the data and saves to file.
    def generate!
      return if empty?

      # Create dir if not exist and clear out old itemsets.
      FileUtils.mkdir_p(priv_dir)
      Dir[File.join(priv_dir, "itemsets-*.csv")].each { |f| File.unlink(f) }

      CSV.open(priv_path, "wb") do |csv|
        generate_header_row(csv)
        option_sets_for_external_csv.each do |os|
          generate_subtree(os.arrange_with_options, csv, os.max_depth)
        end
      end
    end

    # Generates CSV header.
    def generate_header_row(csv)
      row = %w[list_name name]
      row += mission_config.preferred_locales.map { |l| "label::#{language_name(l)}" }
      row += %w[parent_id]
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
      row = [option_set_code(node), node.odk_code]
      row += mission_config.preferred_locales.map { |l| node.option.name(l, fallbacks: true) }
      # Node ID and parent node ID (unless parent is root)
      row << (node.depth > 1 ? node.parent_odk_code : nil)
      row
    end

    # Generates a 'none' CSV row for uneven option sets.
    # options[:type] - Whether this is a child or (great)grandchild of the last non-None node.
    def none_row(node, options)
      row = [option_set_code(node), "none"]
      row += mission_config.preferred_locales.map { |l| "[#{I18n.t('common.blank', locale: l)}]" }
      row << (options[:type] == :child ? node.odk_code : "none")
      row
    end

    def option_sets_for_external_csv
      form.option_sets.select { |set| ODK::DecoratorFactory.decorate(set).external_csv? }
    end

    def option_set_code(node)
      CodeMapper.instance.code_for_item(node.option_set)
    end
  end
end
