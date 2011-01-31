require 'helper'

class TestTrigramIndex < TexticleTestCase
  def setup
    super
    @fm = fake_model
  end

  def test_initialize
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', @fm) do
      name
      value
    end
    assert idx.index.include? "name"
    assert idx.index.include? "value"
  end

  def test_destroy
    idx = Texticle::TrigramIndex.new('ft_index', 'GIN', @fm) do
      name
      value
    end
    idx.destroy
    assert @fm.connected
    assert_equal 1, @fm.executed.length
    executed = @fm.executed.first
    assert_match "DROP index IF EXISTS #{idx.instance_variable_get(:@name)}", executed
  end

  def test_create
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', @fm) do
      name
      value
    end
    idx.create
    assert @fm.connected
    assert_equal 1, @fm.executed.length
    executed = @fm.executed.first
    assert_match idx.to_s, executed
    assert_match "CREATE index #{idx.instance_variable_get(:@name)}", executed
    assert_match "ON #{@fm.table_name}", executed
  end

  def test_to_s
    idx = Texticle::TrigramIndex.new('ft_index', 'GIST', @fm) do
      name
      value
    end
    assert_equal "name gist_trgm_ops, value gist_trgm_ops", idx.to_s
  end
end
