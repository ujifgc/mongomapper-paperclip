# encoding: utf-8

begin
  require "paperclip"
rescue LoadError
  puts "MongoMapper::Paperclip requires that you install the Paperclip gem."
  exit
end

##
# Use mongoid's logger.
module Paperclip
  class << self
    def logger
      MongoMapper.logger || Rails.logger
    end
  end
end

##
# the id of mongoid is not integer, correct the id_partitioin.
Paperclip.interpolates :id_partition do |attachment, style|
  attachment.instance.id.to_s.scan(/.{4}/).join("/")
end

##
# The Mongoid::Paperclip extension
# Makes Paperclip play nice with the Mongoid ODM
#
# Example:
#
#  class User
#    include Mongoid::Document
#    include Mongoid::Paperclip
#
#    has_mongoid_attached_file :avatar
#  end
#
# The above example is all you need to do. This will load the Paperclip library into the User model
# and add the "has_mongoid_attached_file" class method. Provide this method with the same values as you would
# when using "vanilla Paperclip". The first parameter is a symbol [:field] and the second parameter is a hash of options [options = {}].
#
# Unlike Paperclip for ActiveRecord, since MongoDB does not use "schema" or "migrations", Mongoid::Paperclip automatically adds the neccesary "fields"
# to your Model (MongoDB collection) when you invoke the "#has_mongoid_attached_file" method. When you invoke "has_mongoid_attached_file :avatar" it will
# automatially add the following fields:
#
#  field :avatar_file_name,    :type => String
#  field :avatar_content_type, :type => String
#  field :avatar_file_size,    :type => Integer
#  field :avatar_updated_at,   :type => DateTime
#
module MongoMapper
  module Paperclip

    ##
    # Extends the model with the defined Class methods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      ##
      # Adds Mongoid::Paperclip's "#has_mongoid_attached_file" class method to the model
      # which includes Paperclip and Paperclip::Glue in to the model. Additionally
      # it'll also add the required fields for Paperclip since MongoDB is schemaless and doesn't
      # have migrations.
      def has_mm_attached_file(field, options = {})

        ##
        # Include Paperclip and Paperclip::Glue for compatibility
        unless self.ancestors.include?(::Paperclip)
          include ::Paperclip
          include ::Paperclip::Glue
        end

        ##
        # Invoke Paperclip's #has_attached_file method and passes in the
        # arguments specified by the user that invoked Mongoid::Paperclip#has_mongoid_attached_file
        has_attached_file(field, options)

        ##
        # Define the necessary collection fields in Mongoid for Paperclip
        key :"#{field}_file_name",    String
        key :"#{field}_content_type", String
        key :"#{field}_file_size",    Integer
        key :"#{field}_updated_at",   Time
      end

    end

  end
end

module MongoMapper
  module Plugins
    module EmbeddedCallbacks
      module InstanceMethods
        def run_callbacks(callback, opts = nil, &block)
          embedded_docs = []

          embedded_associations.each do |association|
            embedded_docs += Array(get_proxy(association).send(:load_target))
          end

          block = embedded_docs.inject(block) do |chain, doc|
            if doc.class.respond_to?("_#{callback}_callbacks")
              lambda { doc.run_callbacks(callback, &chain) }
            else
              chain
            end
          end
          super callback, &block
        end
      end
    end
  end
end

module Paperclip
  class Attachment
    def updated_at
      time = instance_read(:updated_at)
      time && time.to_time.to_f.to_i
    end
  end
end
