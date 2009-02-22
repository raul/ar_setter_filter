ar\_setter\_filter
================

Plugin to add or chain filters to several ActiveRecord attributes setters at a time.

Usage
-----

    setter_filter [:first_filter, :second_filter] # filters applied to all attributes
    
or

    setter_filter [:first_filter, :second_filter], :only => [:first_name, :last_name]
    setter_filter [:other, :different, :filters], :only => [:bio, :birthdate]

You must not use the same attribute on different setter_filter calls:

    setter_filter [:a, :b], :only => [:name, :website]
    setter_filter [:c, :d, :e], :only => [:website, :bio, :birthdate] # website again?!? DON'T!

Instead you should extract the repeated attribute to its own setter_filter line:

    setter_filter [:a, :b], :only => [:name]
    setter_filter [:c, :d, :e], :only => [:bio, :birthdate]
    setter_filter [:a, :b, :c, :d, :e], :only => [:website]

A filter can be any instance method which follows this convention:

    def my_gorgeous_filter(new_value)
      # do whatever you want
      # Just remember to return the desired new_value, 
      # as it will be the incoming value for the next filter.
      # The value returned by the last filter will be stored on the database.
    end

Example:

    setter_filter [:downcase, :remove_vowels], :only => [:example]
  
    def downcase(new_value) # if new_value = "FOO"
      new_value.downcase    # will return "foo"
    end
  
    def remove_vowels(new_value) # will receive "foo"
      new_value.gsub(/aeiou/,'') # will return "f", to be stored on the db
    end

Motivation
----------

I usually need to filter some attributes values before storing them, specially 
when it comes to string or text fields: cleaning HTML, applying Markdown/bbcode/whatever, 
adding `http://` to URLs if necessary, updating related fields at the same time, etc.

The best way to get it done is overloading the attribute setter, but we can't use `alias_method_chain` here. 
Fortunately, there seems to be [a common, easy pattern](http://adam.blog.heroku.com/past/2007/11/13/2007111322303440307/) 
to apply one filter to one attribute's setter:

    def name=(new_name)
      # your filter here! (For example you can modify new_name before storing it)
      write_attribute :name, new_name # the value is actually stored on db here
    end

This is really nice if you just need to apply one filter to one attribute at a time. There are some
plugins which make use of this pattern on several useful ways. For example, I like to sanitize all my
text fields before storing them, so instead of writing the previous code to each attribute I use a plugin 
to do something like:

    class Project < ActiveRecord::Base

      sanitize_html :only => [:name, :client, :client_url, :company, :company_url]
    
    end

The plugin declares a `sanitize_html` class method which applies the pattern to the selected attributes. Pretty cool!

But today I need to apply one more filter to several attributes. It's a very simple filter, I just 
need to format the URLs to follow some conventions (i.e: add the 'http://' if the user missed it, etc).

I could have it working with:

    sanitize_html :only => [:name, :client, :company]
    
    def company_url=
      # look for the plugin's sanitizing method to invoke it,
      # and now apply my own format_url filter
      write_attribute :company_url
    end

    def client_url=
      # look for the plugin's sanitizing method to invoke it,
      # and now apply my own format_url filter
      write_attribute :client_url
    end
    
...though it's not very DRY. I could try to improve it:

    [:company_url, :client_url].each do |attribute|
      # define a setter following the last examples
    end

...but I actually don't like it.

I could also create a new plugin to customize the behaviour and call it `sanitize_html_and_another_filter`...hmpf.

I've realized that what I really would like to write is something like:

    setter_filter [:sanitize_html], :only => [:name, :client, :company]
    setter_filter [:sanitize_html, :another_filter], :only => [client_url, :company_url]

and be sure that the given filter/s will be applied in the same order as they are declared.

...and that's why I wrote this plugin. But hey, if you know a better solution please contact me!
