module Devise
  module Orm
    module CouchRestModel
      module Hook        
        def devise_modules_hook!
          extend Schema
          create_views_by_authentication_keys
          yield
          return unless Devise.apply_schema
          devise_modules.each { |m| send(m) if respond_to?(m, true) }
        end

        private
        def create_views_by_authentication_keys
          authentication_keys.each do |key_name|
            view_by key_name
          end
          view_by :remember_token
        end
      end

      module Schema
        include Devise::Schema
        # Tell how to apply schema methods.
        def apply_devise_schema(name, type, options={})          
          return unless Devise.apply_schema
          type = String if name == :sign_in_count
          type = Time if type == DateTime
          if type != String
            property name, {:cast_as => type}.merge(options)
          else
            property name
          end
        end

        def find_for_authentication(conditions)
          find(:conditions => conditions)
        end

        def find(*args)
          options = args.extract_options!
          raise "You can't search with more than one condition yet =(" if options[:conditions].keys.size > 1
          
          find_by_key_and_value(options[:conditions].keys.first, options[:conditions].values.first)
        end

        private
        def find_by_key_and_value(key, value)
          if key == :id
            get(value)
          else
            send("by_#{key}", {:key => value, :limit => 1}).first
          end
        end
      end
    end
  end
end

CouchRest::Model::Base.class_eval do
  extend Devise::Models
  extend Devise::Orm::CouchRestModel::Hook
end