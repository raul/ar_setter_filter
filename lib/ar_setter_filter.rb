module ActiveRecord

  module SetterFilter

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def setter_filter(filters, filtered_fields = nil)
        filtered_fields ||= column_names_except_id
        filtered_fields.each do |field|
          define_method("#{field.to_s}=") do |new_value|
            filters.each{ |filter| new_value = send(filter, field, new_value) }
            write_attribute field, new_value
          end
        end
      end
      
      def column_names_except_id
        self.columns.collect{ |column| column.name } - ['id']
      end
      
    end # ClassMethods
    
  end # SetterFilter
  
end # ActiveRecord

ActiveRecord::Base.send(:include, ActiveRecord::SetterFilter)