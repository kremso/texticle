module Texticle
  class TrigramIndex < Texticle::Index # :nodoc:
    def initialize name, type, model_class, &block
      @name           = name
      @type           = type
      @model_class    = model_class
      @index_columns  = []
      @string         = nil
      instance_eval(&block)
    end

    def create_sql
      <<-eosql.chomp
CREATE index #{@name}
        ON #{@model_class.table_name}
        USING #{@type} (#{to_s})
      eosql
    end

    def destroy_sql
      "DROP index IF EXISTS #{@name}"
    end

    def to_s
      return @string if @string
      @string = @index_columns.map { |c| "#{c} #{@type.downcase}_trgm_ops" }.join(', ')
    end

    def method_missing name
      @index_columns << name.to_s
    end
  end
end
