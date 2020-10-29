# frozen_string_literal: true

# Behaviors that handle replicating creation and updates to copies of core objects (forms, questions, etc.)
# within and across missions.
module Replication::Replicable
  extend ActiveSupport::Concern

  # A basic list of attributes that we don't want to copy from the src_obj to the dest_obj.
  ATTRIBS_NOT_TO_COPY = %w[id created_at updated_at mission_id standard_copy original_id ancestry].freeze

  included do
    after_save :sync_chosen_attributes

    # dsl-style method for setting options from base class
    # backward_assocs denotes a fk to an object copied before this one in the replication process
    def self.replicable(options = {})
      options[:child_assocs] = Array.wrap(options[:child_assocs])
      options[:backward_assocs] = Array.wrap(options[:backward_assocs])
      options[:dont_copy] = Array.wrap(options[:dont_copy]).map(&:to_s)
      class_variable_set("@@replicable_opts", options)
    end

    # cleaner accessor for replication options
    def self.replicable_opts
      memoize_class_var(:replicable_opts, nil)
    end

    # Gets a list of columns (strings) of this object that should NOT be copied to the dest obj
    def self.attribs_to_replicate
      foreign_keys = (child_assocs + backward_assocs).map do |assoc|
        assoc.foreign_key.to_s if assoc.belongs_to?
      end
      column_names - ATTRIBS_NOT_TO_COPY - replicable_opts[:dont_copy].map(&:to_s) - foreign_keys
    end

    def self.child_assocs
      memoize_class_var(:child_assocs, build_assoc_wrappers(:child))
    end

    def self.backward_assocs
      memoize_class_var(:backward_assocs, build_assoc_wrappers(:backward))
    end

    def self.second_pass_backward_assocs
      memoize_class_var(:second_pass_backward_assocs, backward_assocs.select(&:second_pass?))
    end

    def self.build_assoc_wrappers(type)
      replicable_opts[:"#{type}_assocs"].map { |a| Replication::AssocProxy.get(self, a) }.compact
    end

    # Whether we can reuse an object of this class when replicating (assuming it's not the source object).
    # Consults the dont_reuse replication option if given (it can be a boolean or a proc).
    def self.replication_reusable?(replicator)
      return false unless standardizable?
      return true unless replicable_opts.key?(:dont_reuse)
      dont_reuse = replicable_opts[:dont_reuse]
      return !dont_reuse.call(replicator) if dont_reuse.is_a?(Proc)
      !dont_reuse
    end

    def self.has_ancestry?
      respond_to?(:check_ancestry_integrity!)
    end

    def self.standardizable?
      respond_to?(:standardizable_included?)
    end

    def self.memoize_class_var(name, value)
      class_variable_set("@@#{name}", value) unless class_variable_defined?("@@#{name}")
      class_variable_get("@@#{name}")
    end
  end

  # There are three replicator modes passed via the mode parameter:
  # * :clone      Make a copy of the object and its decendants in the same mission (or admin mode).
  # * :to_mission Copy/update a standard object and its decendants to a particular different mission.
  #               requires dest_mission parameter
  # * :promote    Creates standard objects from a non-standard object.
  # Examples:
  # obj.replicate(mode: :clone)
  # obj.replicate(mode: :to_mission, dest_mission: m)
  # obj.replicate(mode: :promote)
  def replicate(options = nil)
    raise "replication mode is required" unless options[:mode]
    if options[:mode] == :to_mission && !options[:dest_mission]
      raise "dest_mission must be given for to_mission mode"
    end
    if options[:mode] != :to_mission && options[:dest_mission]
      raise "dest_mission only valid for to_mission mode"
    end

    Replication::Replicator.new(options.merge(source: self)).replicate
  end

  # convenience method for replication options
  def replicable_opts
    self.class.replicable_opts
  end

  # Not all replicable objects are standardizable.
  def standardizable?
    self.class.standardizable?
  end

  private

  # Raises an error if the given sql returns any results.
  def assert_no_results(sql, msg)
    raise "Assertion failed: #{msg}" unless self.class.find_by_sql(sql).empty?
  end

  # Syncs attributes chosen for syncing with copies via the ":sync' option in the replicable declaration.
  def sync_chosen_attributes
    return unless standardizable? && standard?

    copies.not_standard.find_each do |c|
      Array.wrap(replicable_opts[:sync]).each do |a|
        sync_attribute_with_copy(a, c)
      end
      c.save(validate: false)
    end
    true
  end

  # Sync the given attribut with the given copy, avoiding naming conflicts
  def sync_attribute_with_copy(attrib_name, copy)
    # Ensure uniqueness if appropriate.
    uniqueness = replicable_opts[:uniqueness] || {}
    val = if uniqueness[:field] == attrib_name
            Replication::UniqueFieldGenerator.new(klass: self.class, orig_id: id, exclude_id: copy.id,
                                                  mission_id: copy.mission_id, field: attrib_name,
                                                  style: uniqueness[:style]).generate
          else
            send(attrib_name)
          end
    copy.send("#{attrib_name}=", val)
  end
end
