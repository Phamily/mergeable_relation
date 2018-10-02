require 'mergeable_relation/helpers'
require 'mergeable_relation/scope_maintenance'

module Mergeable
  class Relation < ActiveRecord::Relation
    extend  Mergeable::ScopeMaintenance
    include Mergeable::Helpers

    alias_method :super_where, :where

    update_mergeless_before_scope_methods

    class MergedWhereChain < ActiveRecord::Relation::WhereChain
      include Mergeable::Helpers
      def not(opts, *rest)
        mergeless = @scope.instance_variable_get :@mergeless_scope
        if opts.is_a?(Hash) && opts.values.all? { |e| e.respond_to?(:merge) }
          Rails.logger.info("merged_where_chain.not@merged:\n" + merge_opts_wheres_and_not_wheres(mergeless, true, opts, *rest).to_sql)
          merge_opts_wheres_and_not_wheres mergeless, true, opts, *rest
        else
          Rails.logger.info("merged_where_chain.not@mergeless:\n" + mergeless_scope.super_where.not(opts, *rest).to_sql)
          # Update mergeless_scope to faked result of super
          @scope.instance_variable_set :@mergeless_scope, mergeless.super_where.not(opts, *rest)
          super
        end
      end
    end

    class WhereChain < ActiveRecord::Relation::WhereChain
      def not(opts, *rest)
        # Update mergeless_scope to faked result of super (if merge_where/merge_where.not exist in the chain)
        mergeless = @scope.instance_variable_get(:@mergeless_scope)

        unless mergeless.nil?
          @scope.instance_variable_set(:@mergeless_scope, mergeless.super_where.not(opts, *rest))
          Rails.logger.info("merged_where_chain.not@mergeless:\n" + mergeless_scope.super_where.not(opts, *rest).to_sql)
        end
        super
      end
    end

    def where(opts = :chain, *rest)
      # No need to define mergeless_scope if it hasn't already been defined (i.e. where_merge hasn't been called yet)
      return super unless @mergeless_scope
      if opts == :chain
        WhereChain.new(spawn)
      elsif opts.blank?
        self
      else
        # Update mergeless_scope to faked result of super
        @mergeless_scope = @mergeless_scope.super_where(opts, *rest)

        Rails.logger.info("merge_chain.where@mergeless:\n" + @mergeless_scope.to_sql)

        super
      end
    end

    def merge_where(opts = :chain, *rest)
      @mergeless_scope ||= self

      if opts == :chain
        MergedWhereChain.new(spawn)
      elsif opts.blank?
        self
      elsif opts.is_a?(Hash) && opts.values.all? { |e| e.respond_to?(:merge) }
        Rails.logger.info("merge_chain.merge_where@merged:\n" + merge_opts_wheres_and_not_wheres(@mergeless_scope, false, opts, *rest).to_sql)

        merge_opts_wheres_and_not_wheres @mergeless_scope, false, opts, *rest
      else
        @mergeless_scope = @mergeless_scope.super_where(opts, *rest)
        Rails.logger.info("merge_chain.merge_where@mergeless:\n" + @mergeless_scope.to_sql)
        super_where(opts, *rest)
      end
    end
  end
end
