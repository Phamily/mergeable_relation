require 'mergeable_relation/active_record_extension'

module Mergeable
  class Engine < ::Rails::Engine

    isolate_namespace Mergeable

    ActiveSupport.on_load :active_record do
      extend Mergeable::ActiveRecordExtension
      define_singleton_method(:merge_where, method(:where))
    end
  end
end
