require 'mergeable_relation/relation'

module Mergeable
  module ActiveRecordExtension
    def merge_chain
      Mergeable::Relation.new(all.klass, all.table, all.values)
    end
  end
end
