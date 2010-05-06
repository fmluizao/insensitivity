# encoding: UTF-8
module Guenka #:nodoc:
  module Insensitivity #:nodoc:

    # 
    # Change the WHERE conditions to translate the field removing accents and applying lowercase
    # 
    #   class Foo < ActiveRecord::Base
    #     insensible :field1, :field2
    #   end
    #
    #   Foo.find_by_field1('bla')
    #   SELECT * FROM foos 
    #   WHERE TRANSLATE(LOWER(widgets.field1), 
    #       'âãäåāăąèééêëēĕėęěìíîïìĩīĭóôõöōŏőùúûüũūŭůç', 
    #       'aaaaaaaeeeeeeeeeeiiiiiiiiooooooouuuuuuuuc') = 'bla'
    #
    #   Foo.find(:first, :conditions => ['field1 = ?', 'bla'], :order => 'field1')
    #   SELECT * FROM foos 
    #   WHERE TRANSLATE(LOWER(widgets.field1), 
    #       'âãäåāăąèééêëēĕėęěìíîïìĩīĭóôõöōŏőùúûüũūŭůç', 
    #       'aaaaaaaeeeeeeeeeeiiiiiiiiooooooouuuuuuuuc') = 'bla' 
    #   ORDER BY field1 LIMIT 1
    #
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      
      def insensible(*attrs)
        class_inheritable_accessor :_insensible_fields
        self._insensible_fields = attrs
         
        unless insensible? # don't let AR call this twice
          class << self
            alias_method :construct_finder_sql_without_insensitivity, :construct_finder_sql
            alias_method :construct_calculation_sql_without_insensitivity, :construct_calculation_sql
          end
        end
        include InstanceMethods
      end
      
      def insensible?
        self.included_modules.include?(InstanceMethods)
      end
      
      def insensible_fields
        self._insensible_fields ||= []
      end
    end

    module InstanceMethods #:nodoc:
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        private
        def construct_finder_sql(options)
          sql = construct_finder_sql_without_insensitivity(options)
          insert_insensible_clause_in_query(sql)
        end
        
        def construct_calculation_sql(operation, column_name, options)
          sql = construct_calculation_sql_without_insensitivity(operation, column_name, options)
          insert_insensible_clause_in_query(sql)
        end
        
        def insert_insensible_clause_in_query(sql)
          return sql if insensible_fields.size == 0 # dont have insensibleble fields
          
          splitted_sql = sql.split(" WHERE ")
          return sql if splitted_sql.size == 1 # dont have the where clause
          
          first_clause = splitted_sql.first
          where_clause = " WHERE #{splitted_sql.last}"
          
          # if have GROUP BY
          tmp = where_clause.split(" GROUP ")
          if tmp.size > 1
            where_clause = tmp.first
            last_clause = " GROUP #{tmp.last}"
          else
            # if have ORDER
            tmp = where_clause.split(" ORDER ")
            if tmp.size > 1
              where_clause = tmp.first
              last_clause = " ORDER #{tmp.last}"
            end
          end
          
          # change the original by the insensible in the where clause
          insensible_fields.each do |field|
            where_clause.gsub!(/("#{table_name}"\."#{field}"|\b#{table_name}\.#{field}\b|\b#{field}\b)/, insensible_clause_for('\1'))
          end
          
          # build the sql again
          "#{first_clause}#{where_clause}#{last_clause}"
        end

        def insensible_clause_for(field)
          %{TRANSLATE(LOWER(#{field}), 'áàâãäåāăąèééêëēĕėęěìíîïìĩīĭóôõöōŏőùúûüũūŭůç', 'aaaaaaaaaeeeeeeeeeeiiiiiiiiooooooouuuuuuuuc')}
        end

      end

    end
    
  end
end
