module Guenka #:nodoc:
  module Insensitivity #:nodoc:

    # 
    # Change the WHERE conditions to use the _search field instead of the default field.
    # 
    # This assumes the table has a _search field for every field declared as insensible
    #
    #   class Foo < ActiveRecord::Base
    #     insensible :field1, :field2
    #   end
    #
    #   Foo.find_by_field1('bla')
    #   SELECT * FROM foos WHERE widgets.field1_search = 'bla'
    #
    #   Foo.find(:first, :conditions => ['field1 = ?', 'bla'], :order => 'field1')
    #   SELECT * FROM foos WHERE field1_search = 'bla' ORDER BY title LIMIT 1
    #
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      
      def insensible(*attrs)
        unless insensible? # don't let AR call this twice
          @@insensible_fields = attrs
          
          before_save :assign_insensible_fields

          define_method :assign_insensible_fields do
            attrs.each do |attr|
              attr_value = send("#{attr}")
              write_attribute("#{attr}_search", attr_value.to_s.remover_acentos.downcase)
            end
          end
          
          class << self
            alias_method :construct_finder_sql_without_insensitivity, :construct_finder_sql
          end
        end
        include InstanceMethods
      end
      
      def make_insensible!
        transaction do
          all.each do |obj|
            insensible_fields.each do |field|
              obj["#{field}_search"] = obj[field].remover_acentos.downcase
            end
            obj.save(false) #dont perform validations
          end
        end
      end
      
      def insensible?
        self.included_modules.include?(InstanceMethods)
      end
      
      def insensible_fields
        @@insensible_fields ||= []
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
          return sql if insensible_fields.size == 0 #dont have insensibleble fields
          
          splitted_sql = sql.split(" WHERE ")
          return sql if splitted_sql.size == 1 #dont have the where clause
          
          first_clause = splitted_sql.first
          where_clause = " WHERE #{splitted_sql.last}"
          
          #if have GROUP BY
          tmp = where_clause.split(" GROUP ")
          if tmp.size > 1
            where_clause = tmp.first
            last_clause = " GROUP #{tmp.last}"
          else
            #if have ORDER
            tmp = where_clause.split(" ORDER ")
            if tmp.size > 1
              where_clause = tmp.first
              last_clause = " ORDER #{tmp.last}"
            end
          end
          
          #change the original by the insensible in the where clause
          insensible_fields.each do |field|
            where_clause.gsub!(/\b#{field}\b/, "#{field}_search")
          end
          
          #build the sql again
          "#{first_clause}#{where_clause}#{last_clause}"
        end

      end

    end
    
  end
end
