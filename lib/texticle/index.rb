module Texticle
  class Index # :nodoc:
    attr_accessor :index_columns

    def self.find_constant_of(filename)
      File.basename(filename, '.rb').pluralize.classify.constantize
    end

    def create
      sql = create_sql
      sql = [sql] unless sql.respond_to? :each
      sql.each { |q| @model_class.connection.execute q }
    end

    def destroy
      sql = destroy_sql
      sql = [sql] unless sql.respond_to? :each
      sql.each { |q| @model_class.connection.execute q }
    end
  end
end
