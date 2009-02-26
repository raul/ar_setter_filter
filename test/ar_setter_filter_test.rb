require 'rubygems'
require 'test/unit'
require 'mocha'
require 'active_record'
require File.join(File.dirname(__FILE__), '/../init')

# Prepare database
require 'tempfile'
db_file = Tempfile.new("db")
ActiveRecord::Base.establish_connection({:adapter => 'sqlite3', :dbfile => db_file.path})
ActiveRecord::Schema.define do
  create_table :my_models, :force => true do |t|
    t.column :name, :string
    t.column :bio, :text
  end
end

# Available ActiveRecord filters
module ActiveRecord
  class Base
    def downcase(attrib_name, new_value)
      new_value.downcase
    end
    def remove_down_vowels(attrib_name, new_value)
      new_value.gsub(/[aeiou]/,'')
    end
  end
end


class ARSetterFilterTest < Test::Unit::TestCase

  def setup
    @val  = 'value assigned to the setter'
    @val1 = 'value returned by the filter1'
    @val2 = 'value returned by the filter2'
  end

  # applied sequentially to all attributes:
  
  class MyModelAll < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1, :filter2]
  end
  
  def test_filters_applied_sequentially_to_all_attributes
    @model = MyModelAll.new

    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name

    @model.expects(:filter1).with(:bio, @val).returns  @val1
    @model.expects(:filter2).with(:bio, @val1).returns @val2
    @model.bio = @val
    assert_equal @val2, @model.bio
  end


  # selected with only and except:
  
  class MyModelOnlyExcept < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1, :filter2], :only => [:name]
    setter_filter [:filter2, :filter1], :except => [:name]
  end
  
  def test_filters_chained_combining_only_and_except
    @model = MyModelOnlyExcept.new

    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name

    @model.expects(:filter2).with(:bio, @val).returns @val2
    @model.expects(:filter1).with(:bio, @val2).returns  @val1
    @model.bio = @val
    assert_equal @val1, @model.bio
  end
  
 
  # chained on several lines with onlies:
  
  class MyModelSeveralOnlies < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1], :only => [:name]
    setter_filter [:filter2], :only => [:name]
  end
  
  def test_filters_chained_on_several_lines_with_onlies
    @model = MyModelSeveralOnlies.new
    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name
    
    @model.bio = @val
    assert_equal @val, @model.bio
  end


  # chained on several lines with excepts:
  
  class MyModelSeveralExcepts < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1], :except => [:bio]
    setter_filter [:filter2], :except => [:bio]
  end
  
  def test_filters_chained_on_several_lines_with_excepts
    @model = MyModelSeveralExcepts.new
    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name
  end


  # chained on several lines combining onlies and excepts:
  
  class MyModelSeveraOnliesExcepts < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1], :only => [:name]
    setter_filter [:filter2], :except => [:bio]
  end
  
  def test_filters_chained_on_several_lines_combining_onlues_and_excepts
    @model = MyModelSeveraOnliesExcepts.new
    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name
  end

  
  # selected by only_types:
  
  class MyModelOnlyTypes < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1, :filter2], :only_types => [:string]
  end
  
  def test_selected_by_only_types
    @model = MyModelOnlyTypes.new
  
    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name
  
    @model.bio = @val
    assert_equal @val, @model.bio
  end


  # selected by except_types:
  
  class MyModelExceptTypes < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1, :filter2], :except_types => [:text]
  end
  
  def test_selected_by_except_types
    @model = MyModelExceptTypes.new
  
    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name
  
    @model.bio = @val
    assert_equal @val, @model.bio
  end
  
  
  # chained by only_types and except_types:
  
  class MyModelOnlyExceptTypes < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:filter1], :only_types => [:string]
    setter_filter [:filter2], :except_types => [:text]
  end
  
  def test_chained_by_only_types_and_except_types
    @model = MyModelOnlyExceptTypes.new
  
    @model.expects(:filter1).with(:name, @val).returns  @val1
    @model.expects(:filter2).with(:name, @val1).returns @val2
    @model.name = @val
    assert_equal @val2, @model.name
  
    @model.bio = @val
    assert_equal @val, @model.bio
  end

end
