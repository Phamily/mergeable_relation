module Mergeable
  module Helpers
    def merge_opts_wheres_and_not_wheres(mergeless_scope, negated,  opts, *rest)

      merged_wheres     = mergeless_scope.instance_variable_get(:@merged_wheres)
      merged_where_nots = mergeless_scope.instance_variable_get(:@merged_where_nots)

      if negated
        merged_where_nots, opts = merge_opts_and_target(opts, merged_where_nots)
        merged_scope = opts.reduce(mergeless_scope) { |chain, (table, conditions)| chain.super_where.not(conditions) }
        merged_scope = touch_mergeless(mergeless_scope, merged_scope, :@merged_where_nots, merged_where_nots)
        merged_scope = merged_wheres.reduce(merged_scope) { |chain, (table, conditions)| chain.super_where(conditions) } if merged_wheres
      else
        merged_wheres, opts = merge_opts_and_target(opts, merged_wheres)
        merged_scope = opts.reduce(mergeless_scope) { |chain, (table, conditions)| chain.super_where(conditions) }
        merged_scope = touch_mergeless(mergeless_scope, merged_scope, :@merged_wheres, merged_wheres)
        merged_scope = merged_where_nots.reduce(merged_scope) { |chain, (table, conditions)| chain.super_where.not(conditions) } if merged_where_nots
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
      conditions_by_table = opts.each_with_object(merging_target) do |(column, conditions), new_opts|
        new_opts[conditions.table_name] ||= {}
        if merging_target[conditions.table_name] && merging_target[conditions.table_name][column]
          merging_target[conditions.table_name][column] = merging_target[conditions.table_name][column].merge(conditions)
          new_opts[conditions.table_name][column]       = merging_target[conditions.table_name][column].merge(conditions)
        elsif conditions.respond_to?(:merge)
          merging_target[conditions.table_name] ||= {}
          merging_target[conditions.table_name][column] = conditions
          new_opts[conditions.table_name][column]       = conditions
        else
          new_opts[conditions.table_name][column] = conditions
        end
      end
      [merging_target, conditions_by_table]
    end

  end
end
