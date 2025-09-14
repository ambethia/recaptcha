# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

require 'recaptcha/configuration'
require 'recaptcha/helpers'
require 'recaptcha/reply'
require 'recaptcha/adapters/controller_methods'
require 'recaptcha/adapters/view_methods'
if defined?(Rails)
  require 'recaptcha/railtie'
end

module Recaptcha
  DEFAULT_TIMEOUT = 3

  class RecaptchaError < StandardError
  end

  class VerifyError < RecaptchaError
  end

  # Gives access to the current Configuration.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allows easy setting of multiple configuration options. See Configuration
  # for all available options.
  #--
  # The temp assignment is only used to get a nicer rdoc. Feel free to remove
  # this hack.
  #++
  def self.configure
    config = configuration
    yield(config)
  end

  def self.with_configuration(config)
    original_config = {}

    config.each do |key, value|
      original_config[key] = configuration.send(key)
      configuration.send("#{key}=", value)
    end

    yield if block_given?
  ensure
    original_config.each { |key, value| configuration.send("#{key}=", value) }
  end

  def self.skip_env?(env)
    configuration.skip_verify_env.include?(env || configuration.default_env)
  end

  def self.invalid_response?(resp)
    resp.empty? || resp.length > configuration.response_limit || resp.length < configuration.response_minimum
  end

  def self.verify_via_api_call(response, options)
    if Recaptcha.configuration.enterprise
      verify_via_api_call_enterprise(response, options)
    else
      verify_via_api_call_free(response, options)
    end
  end

  def self.verify_via_api_call_enterprise(response, options)
    site_key = options.fetch(:site_key) { configuration.site_key! }
    api_key = options.fetch(:enterprise_api_key) { configuration.enterprise_api_key! }
    project_id = options.fetch(:enterprise_project_id) { configuration.enterprise_project_id! }

    query_params = { 'key' => api_key }
    body = { 'event' => { 'token' => response, 'siteKey' => site_key } }
    body['event']['expectedAction'] = options[:action] if options.key?(:action)
    body['event']['userIpAddress'] = options[:remote_ip] if options.key?(:remote_ip)

    raw_reply = api_verification_enterprise(query_params, body, project_id, timeout: options[:timeout])
    reply = Reply.new(raw_reply, enterprise: true)
    result = reply.success?(options)
    options[:with_reply] == true ? [result, reply] : result
  end

  def self.verify_via_api_call_free(response, options)
    secret_key = options.fetch(:secret_key) { configuration.secret_key! }
    verify_hash = { 'secret' => secret_key, 'response' => response }
    verify_hash['remoteip'] = options[:remote_ip] if options.key?(:remote_ip)

    raw_reply = api_verification_free(verify_hash, timeout: options[:timeout], json: options[:json])
    reply = Reply.new(raw_reply, enterprise: false)
    result = reply.success?(options)
    options[:with_reply] == true ? [result, reply] : result
  end

  def self.http_client_for(uri:, timeout: nil)
    timeout ||= DEFAULT_TIMEOUT
    http = if configuration.proxy
      proxy_server = URI.parse(configuration.proxy)
      Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
    else
      Net::HTTP
    end
    instance = http.new(uri.host, uri.port)
    instance.read_timeout = instance.open_timeout = timeout
    instance.use_ssl = true if uri.port == 443

    instance
  end

  def self.api_verification_free(verify_hash, timeout: nil, json: false)
    if json
      uri = URI.parse(configuration.verify_url)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json; charset=utf-8'
      request.body = JSON.generate(verify_hash)
    else
      query = URI.encode_www_form(verify_hash)
      uri = URI.parse("#{configuration.verify_url}?#{query}")
      request = Net::HTTP::Get.new(uri.request_uri)
    end
    http_instance = http_client_for(uri: uri, timeout: timeout)
    JSON.parse(http_instance.request(request).body)
  end

  def self.api_verification_enterprise(query_params, body, project_id, timeout: nil)
    query = URI.encode_www_form(query_params)
    uri = URI.parse("#{configuration.verify_url}/#{project_id}/assessments?#{query}")
    http_instance = http_client_for(uri: uri, timeout: timeout)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Referer'] = Rails.application.default_url_options[:host] if defined? Rails.application
    request['Content-Type'] = 'application/json; charset=utf-8'
    request.body = JSON.generate(body)
    JSON.parse(http_instance.request(request).body)
  end
end
