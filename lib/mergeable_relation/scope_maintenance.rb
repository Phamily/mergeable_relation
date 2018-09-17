module Mergeable
  module ScopeMaintenance
    def update_mergeless_before_scope_methods
      (ActiveRecord::Relation::VALUE_METHODS + [:merge]).each { |method_name| inject_touch_mergeless(method_name) }
    end

  private

    def inject_touch_mergeless(method_name)
      original_method = instance_method(method_name)
      define_method(method_name) do |*args, &block|
        @mergeless_scope = original_method.bind(@mergeless_scope).call(*args, &block) if @mergeless_scope
        original_method.bind(self).call(*args, &block)
      end
    end
  end
end
