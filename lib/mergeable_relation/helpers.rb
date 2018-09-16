module Mergeable
  module Helpers
    def merge_opts_wheres_and_not_wheres(mergeless_scope, negated,  opts, *rest)

      merged_wheres     = mergeless_scope.instance_variable_get(:@merged_wheres)
      merged_where_nots = mergeless_scope.instance_variable_get(:@merged_where_nots)

      if negated
        merged_where_nots, opts = merge_opts_and_target(opts, merged_where_nots)
        merged_scope = mergeless_scope.super_where.not(opts, *rest)
        merged_scope = touch_mergeless(mergeless_scope, merged_scope, :@merged_where_nots, merged_where_nots)
        merged_scope = merged_scope.super_where(merged_wheres) if merged_wheres
      else
        merged_wheres, opts = merge_opts_and_target(opts, merged_wheres)
        merged_scope = mergeless_scope.super_where(opts, *rest)
        merged_scope = touch_mergeless(mergeless_scope, merged_scope, :@merged_wheres, merged_wheres)
        merged_scope = merged_scope.super_where.not(merged_where_nots) if merged_where_nots
      end
      merged_scope
    end

  private

    def touch_mergeless(mergeless_scope, merged_scope, merging_symbol, merging_target)
      # Set newly merged conditions as an instance variable on mergeless_scope
      # Add mergeless_scope as an instance property on the scope (to be referenced in chained methods)
      mergeless_scope.instance_variable_set(merging_symbol, merging_target) unless merging_target.nil? || merging_target == {}
      merged_scope.instance_variable_set :@mergeless_scope, mergeless_scope
      merged_scope
    end

    def merge_opts_and_target(opts, merging_target)
      merging_target ||= {}
      opts.each do |column, conditions|
        if merging_target[column]
          merging_target[column] = merging_target[column].merge(conditions)
        elsif conditions.respond_to?(:merge)
          merging_target[column] = conditions
        end
      end
      [merging_target, opts.merge!(merging_target)]
    end

  end
end
