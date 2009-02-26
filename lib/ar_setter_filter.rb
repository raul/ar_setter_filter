module ActiveRecord

  module SetterFilter
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      
      def setter_filters
        class_variable_get(:@@setter_filters)
      end

      private
      
      def setter_filter_selected_attributes(options)
        attribs = content_columns.collect{ |col| col.name.to_sym }
        raise Exception.new("ActiveRecord::SetterFilter admits only one selector per line") if options.keys.size > 1
        return attribs - options[:except].to_a if options[:except]
        return attribs & options[:only].to_a if options[:only]
        return content_columns.select{ |col| options[:only_types].include?(col.type) }.map(&:name).map(&:to_sym) if options[:only_types]
        return content_columns.select{ |col| !options[:except_types].include?(col.type) }.map(&:name).map(&:to_sym) if options[:except_types]
        return attribs
      end
      
      def setter_filter(filters, options = {})
        class_variable_set(:@@setter_filters, {}) unless class_variable_defined?(:@@setter_filters)
        setter_filter_selected_attributes(options).each do |attrib|
          setter_filters[attrib] ||= []
          setter_filters[attrib] += filters.flatten
          define_method("#{attrib.to_s}=") do |new_value|
            self.class.setter_filters[attrib].each{ |filter| new_value = send(filter, attrib, new_value) }
            write_attribute attrib, new_value
          end
        end
      end
      
    end # ClassMethods
    
  end # SetterFilter
  
end # ActiveRecord

ActiveRecord::Base.send(:include, ActiveRecord::SetterFilter)