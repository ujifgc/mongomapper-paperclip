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
        key :"#{field}_updated_at",   DateTime
      end

    end

  end
end
