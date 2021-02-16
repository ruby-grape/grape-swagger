# frozen_string_literal: true

module GrapeSwagger
  class ModelParsers
    include Enumerable

    def initialize
      @parsers = {}
    end

    def register(klass, ancestor)
      @parsers[klass] = ancestor.to_s
    end

    def insert_before(before_klass, klass, ancestor)
      subhash = @parsers.except(klass).to_a
      insert_at = subhash.index(subhash.assoc(before_klass))
      insert_at = subhash.length - 1 if insert_at.nil?
      @parsers = subhash.insert(insert_at, [klass, ancestor]).to_h
    end

    def insert_after(after_klass, klass, ancestor)
      subhash = @parsers.except(klass).to_a
      insert_at = subhash.index(subhash.assoc(after_klass))
      insert_at = subhash.length - 1 if insert_at.nil?
      @parsers = subhash.insert(insert_at + 1, [klass, ancestor]).to_h
    end

    def each
      @parsers.each_pair do |klass, ancestor|
        yield klass, ancestor
      end
    end

    def find(model)
      GrapeSwagger.model_parsers.each do |klass, ancestor|
        return klass if model.ancestors.map(&:to_s).include?(ancestor)
      end
      nil
    end
  end
end
