# frozen_string_literal: true

module Cloning
  # Expands a given set of relations to include all necessary related objects.
  class RelationExpander
    attr_accessor :initial_relations, :relations_by_class, :options

    def initialize(relations, **options)
      self.options = options
      options[:dont_implicitly_expand] ||= []
      self.initial_relations = relations
      self.relations_by_class = relations.group_by(&:klass)
    end

    # Returns a hash of form {ModelClass => [Relation, Relation, ...], ...}, mapping model classes
    # to arrays of Relations.
    def expanded
      initial_relations.each { |r| expand(r) }
      relations_by_class
    end

    private

    def expand(relation)
      (relation.klass.clone_options[:follow] || []).each do |assn_name|
        assn = relation.klass.reflect_on_association(assn_name)

        # dont_implicitly_expand is provided if the caller wants to indicate that one of the initial_relations
        # should cover all relevant rows and therefore implicit expansion is not necessary. This improves
        # performance by simplifying the eventual SQL queries.
        next if options[:dont_implicitly_expand].include?(assn.klass)

        new_rel = if assn.belongs_to?
                    assn.klass.where("id IN (#{relation.select(assn.foreign_key).to_sql})")
                  else
                    assn.klass.where("#{assn.foreign_key} IN (#{relation.select(:id).to_sql})")
                  end
        (relations_by_class[assn.klass] ||= []) << new_rel
        expand(new_rel)
      end
    end
  end
end
