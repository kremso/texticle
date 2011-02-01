require 'helper'

class TestTexticle < TexticleTestCase
  def test_ft_index_method
    x = fake_model
    x.class_eval do
      extend Texticle
      index do
        name
      end
    end
    assert_equal 1, x.full_text_indexes.length
    assert_equal 1, x.named_scopes.length

    x.full_text_indexes.first.create
    assert_match "#{x.table_name}_fts_idx", x.executed.first
    assert_equal :search, x.named_scopes.first.first
  end

  def test_trgm_index_method
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index do
        name
      end
    end
    assert_equal 1, x.trigram_indexes.length
    assert_equal 1, x.named_scopes.length

    x.trigram_indexes.first.create
    assert_match "#{x.table_name}_trgm_idx", x.executed.first
    assert_equal :tsearch, x.named_scopes.first.first
  end

  def test_ft_named_index
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'awesome' do
        name
      end
    end
    assert_equal 1, x.full_text_indexes.length
    assert_equal 1, x.named_scopes.length

    x.full_text_indexes.first.create
    assert_match "#{x.table_name}_awesome_fts_idx", x.executed.first
    assert_equal :search_awesome, x.named_scopes.first.first
  end

  def test_trgm_named_index
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index :name => 'awesome' do
        name
      end
    end
    assert_equal 1, x.trigram_indexes.length
    assert_equal 1, x.named_scopes.length

    x.trigram_indexes.first.create
    assert_match "#{x.table_name}_awesome_trgm_idx", x.executed.first
    assert_equal :tsearch_awesome, x.named_scopes.first.first
  end

  def test_named_scope_select
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'awesome' do
        name
      end
    end
    ns = x.named_scopes.first[1].call('foo')
    assert_match(/^#{x.table_name}\.\*/, ns[:select])
  end
  
  def test_double_quoted_queries
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'awesome'  do
        name
      end
    end
    
    ns = x.named_scopes.first[1].call('foo bar "foo bar"')
    assert_match(/foo & bar & foo\\ bar/, ns[:select])
  end
 
  def test_wildcard_queries
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'awesome' do
        name
      end
    end
    
    ns = x.named_scopes.first[1].call('foo bar*')
    assert_match(/foo & bar:*/, ns[:select])
  end
  
  def test_dictionary_in_select
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'awesome', :dictionary => 'spanish' do
        name
      end
    end

    ns = x.named_scopes.first[1].call('foo')
    assert_match(/to_tsvector\('spanish'/, ns[:select])
    assert_match(/to_tsquery\('spanish'/, ns[:select])
  end

  def test_trgm_type
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index :name => 'awesome', :type => 'GIST' do
        name
      end
    end

    x.trigram_indexes.first.create
    assert_match "USING GIST", x.executed.first
    assert_match "gist_trgm_ops", x.executed.first
  end

  def test_dictionary_in_conditions
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'awesome', :dictionary => 'spanish' do
        name
      end
    end

    ns = x.named_scopes.first[1].call('foo')
    assert_match(/to_tsvector\('spanish'/, ns[:conditions].first)
    assert_equal 'spanish', ns[:conditions][1]
  end

  def test_multiple_named_ft_indices
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'uno' do
        greco
      end
      index :name => 'due' do
        guapo
      end
    end

    assert_equal :search_uno,  x.named_scopes[0].first
    assert_match(/greco/,      x.named_scopes[0][1].call("foo")[:select])
    assert_match(/greco/,      x.named_scopes[0][1].call("foo")[:conditions].first)

    assert_equal :search_due,  x.named_scopes[1].first
    assert_match(/guapo/,      x.named_scopes[1][1].call("foo")[:select])
    assert_match(/guapo/,      x.named_scopes[1][1].call("foo")[:conditions].first)
  end

  def test_multiple_named_trgm_indices
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index :name => 'uno' do
        greco
      end
      trigram_index :name => 'due' do
        guapo
      end
    end

    assert_equal :tsearch_uno,  x.named_scopes[0].first
    assert_match(/greco/,       x.named_scopes[0][1].call("foo")[:select])
    assert_match(/greco/,       x.named_scopes[0][1].call("foo")[:conditions])

    assert_equal :tsearch_due,  x.named_scopes[1].first
    assert_match(/guapo/,       x.named_scopes[1][1].call("foo")[:select])
    assert_match(/guapo/,       x.named_scopes[1][1].call("foo")[:conditions])
  end

  def test_combination_of_ft_and_trgm_indices
    x = fake_model
    x.class_eval do
      extend Texticle
      index :name => 'uno' do
        greco
      end
      trigram_index :name => 'due' do
        guapo
      end
    end

    assert_equal :search_uno,   x.named_scopes[0].first
    assert_match(/greco/,       x.named_scopes[0][1].call("foo")[:select])
    assert_match(/greco/,       x.named_scopes[0][1].call("foo")[:conditions].first)

    assert_equal :tsearch_due,  x.named_scopes[1].first
    assert_match(/guapo/,       x.named_scopes[1][1].call("foo")[:select])
    assert_match(/guapo/,       x.named_scopes[1][1].call("foo")[:conditions])
  end

  def test_trgm_scope_with_or
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index :name => 'awesome', :type => 'GIST', :mode => 'OR' do
        name
        value
      end
    end

    ns = x.named_scopes.first[1].call('foo')
    assert_match(/name % 'foo'/, ns[:conditions])
    assert_match(/value % 'foo'/, ns[:conditions])
  end

  def test_trgm_scope_with_and
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index :name => 'awesome', :type => 'GIST', :mode => 'AND' do
        name
        value
      end
    end

    ns = x.named_scopes.first[1].call('foo', 'boo')
    assert_match(/name % 'foo'/, ns[:conditions])
    assert_match(/value % 'boo'/, ns[:conditions])
  end

  def test_trgm_scope_with_and_and_wrong_parameters
    x = fake_model
    x.class_eval do
      extend Texticle
      trigram_index :name => 'awesome', :type => 'GIST', :mode => 'AND' do
        name
        value
      end
    end

    assert_raise ArgumentError do
      x.named_scopes.first[1].call('foo')
    end
  end
end
