module Texticle
  class Index # :nodoc:
    attr_accessor :index_columns

    def self.find_constant_of(filename)
      File.basename(filename, '.rb').pluralize.classify.constantize
    end

    def create
      @model_class.connection.execute create_sql
    end

    def destroy
      @model_class.connection.execute destroy_sql
    end
  end
end
