# reCAPTCHA model validation, based on SimpleCaptcha
# (SimpleCaptcha Copyright (c) 2008 [Sur http://expressica.com])

module Recaptcha #:nodoc
  module ModelHelpers #:nodoc
    #  class User < ActiveRecord::Base
    #    apply_recaptcha :message => "my customized message"
    #  end
    module ClassMethods
      def apply_recaptcha(options = {})
        instance_variable_set(:@add_to_base, options[:add_to_base])
        instance_variable_set(:@recaptcha_invalid_message, options[:message] || "The words were not entered correctly")
        module_eval do
          attr_accessor :remote_ip, :recaptcha_challenge_field, :recaptcha_response_field, :authenticate_with_recaptcha
          include Recaptcha::ModelHelpers::InstanceMethods
        end
      end
    end
    
    module InstanceMethods
      def save_with_recaptcha
        def self.validate
          super
          verify_recaptcha(:model => self, :attribute => :recaptcha)
        end
        ret = save
        def self.validate
          super
        end
        ret
      end
    end
  end
end

ActiveRecord::Base.module_eval do
  extend Recaptcha::ModelHelpers::ClassMethods
end

