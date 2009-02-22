require 'rubygems'
require 'test/unit'
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
    t.column :address, :string
  end
end

# Available ActiveRecord filters
module ActiveRecord
  class Base
    def downcase(new_value)
      new_value.downcase
    end
    def remove_down_vowels(new_value)
      new_value.gsub(/[aeiou]/,'')
    end
  end
end


class ARSetterFilterTest < Test::Unit::TestCase

  # setter filter applied to all attributes:
  
  class MyModelAllSetters < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:downcase, :remove_down_vowels]
  end
  
  def test_filters_applied_sequentially_to_all_attributes
    @model = MyModelAllSetters.new :name => 'ABCDEabcde', :bio => 'ABCDEabcde', :address => 'ABCDEabcde'
    assert_equal 'bcdbcd', @model.name
    assert_equal 'bcdbcd', @model.bio
    assert_equal 'bcdbcd', @model.address
  end


  # setter filter applied to some selected attributes:
  
  class MyModelSomeSetters < ActiveRecord::Base
    set_table_name 'my_models'
    setter_filter [:downcase, :remove_down_vowels], [:name]
    setter_filter [:remove_down_vowels, :downcase], [:bio]
  end

  def test_filters_applied_only_to_selected_attributes
    @model = MyModelSomeSetters.new :name => 'ABCDEabcde', :bio => 'ABCDEabcde', :address => 'ABCDEabcde'
    assert_equal 'bcdbcd', @model.name
    assert_equal 'abcdebcd', @model.bio
  end

  def test_filters_applied_in_specified_order
    @model = MyModelSomeSetters.new :name => 'ABCDEabcde', :bio => 'ABCDEabcde'
    assert_equal 'bcdbcd', @model.name
    assert_equal 'abcdebcd', @model.bio
  end
  


end
