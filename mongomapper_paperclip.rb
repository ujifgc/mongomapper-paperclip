# encoding: utf-8

begin
  require "paperclip"
rescue LoadError
  puts "MongoMapper::Paperclip requires that you install the Paperclip gem."
  exit
end

module Paperclip
  class << self
    def logger
      MongoMapper.logger || Rails.logger
    end
  end
end

Paperclip.interpolates :id_partition do |attachment, style|
  attachment.instance.id.to_s.scan(/.{4}/).join("/")
end

module MongoMapper
  module Paperclip

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def has_mm_attached_file(field, options = {})

        unless self.ancestors.include?(::Paperclip)
          include ::Paperclip
          include ::Paperclip::Glue
        end

        has_attached_file(field, options)

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
