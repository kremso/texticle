module Texticle
  class TrigramIndex < Texticle::Index # :nodoc:
    def initialize name, type, mode, model_class, &block
      @name           = name
      @type           = type
      @mode           = mode
      @model_class    = model_class
      @index_columns  = []
      @string         = nil
      instance_eval(&block)
    end

    def create_sql
      if @mode == 'AND'
        <<-eosql.chomp
          CREATE index #{@name}
          ON #{@model_class.table_name}
          USING #{@type} (#{column_definition(@index_columns)})
        eosql
      else
        @index_columns.map do |column|
          <<-eosql.chomp
            CREATE index #{@name}_#{column}
            ON #{@model_class.table_name}
            USING #{@type} (#{column_definition(column)})
          eosql
        end
      end
    end

    def destroy_sql
      indexes = @model_class.connection.execute(<<-SQL).select { |idx| idx =~ /trgm_idx/ }
        SELECT indexname FROM pg_indexes WHERE table_name = '#{@model_class.table_name}'
      SQL

      indexes.map { |idx| "DROP INDEX #{idx}" }
    end

    def method_missing name
      @index_columns << name.to_s
    end

    private
    def column_definition(columns)
      columns = [columns] unless columns.respond_to? :each
      columns.map { |c| "#{c} #{@type.downcase}_trgm_ops" }.join(', ')
    end
  end
end
