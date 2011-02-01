require 'helper'

class TestTrigramIndex < TexticleTestCase
  def setup
    super
    @fm = fake_model
  end

  def test_initialize
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', 'AND', @fm) do
      name
      value
    end
    assert idx.index.include? "name"
    assert idx.index.include? "value"
  end

  def test_create_with_and
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', 'AND', @fm) do
      name
      value
    end
    idx.create
    assert @fm.connected
    assert_equal 1, @fm.executed.length
    executed = @fm.executed.first
    assert_match "CREATE index", executed
    assert_match "ON #{@fm.table_name}", executed
  end

  def test_create_with_or
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', 'OR', @fm) do
      name
      value
    end
    idx.create
    assert @fm.connected
    assert_equal 2, @fm.executed.length

    assert_match "CREATE index", @fm.executed[0]
    assert_match "_name", @fm.executed[0]
    assert_match "ON #{@fm.table_name}", @fm.executed[0]

    assert_match "CREATE index", @fm.executed[1]
    assert_match "_value", @fm.executed[1]
    assert_match "ON #{@fm.table_name}", @fm.executed[1]
  end

  def test_drop
    @fm.class_eval do
      class << self
        alias_method :original_execute, :execute
        def execute sql
          original_execute sql
          if sql =~ /FROM pg_indexes/
            return ["fake_model_trgm_idx_name", "fake_model_trgm_idx_value", "fake_model_ft_idx"]
          end
        end
      end
    end
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', 'OR', @fm) do
      name
      value
    end
    idx.destroy
    assert @fm.connected
    assert_equal 3, @fm.executed.length
    assert_match "DROP INDEX fake_model_trgm_idx_name", @fm.executed[1]
    assert_match "DROP INDEX fake_model_trgm_idx_value", @fm.executed[2]
  end
end
