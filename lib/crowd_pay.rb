require 'active_model'
require 'faraday'
require 'json'
require 'crowd_pay/version'

module CrowdPay
  autoload :Account,      'crowd_pay/account'
  autoload :Asset,        'crowd_pay/asset'
  autoload :Escrow,       'crowd_pay/escrow'
  autoload :Investor,     'crowd_pay/investor'
  autoload :Transaction,  'crowd_pay/transaction'
  autoload :Verification, 'crowd_pay/verification'

  class ConnectionManager
    class << self
      attr_accessor :domain, :api_key, :portal_key, :by_pass_validation, :authorization
    end

    @@connections = {}
    @@conn_options_by_thread = {}

    def self.connection
      conn_options = @@conn_options_by_thread[Thread.current.object_id] || {}
      get_connection_for(conn_options)
    end

    #  Run the block with the specific connection options passed
    #
    def self.with(options)
      @@conn_options_by_thread[Thread.current.object_id] = options
      yield if block_given?
      @@conn_options_by_thread[Thread.current.object_id] = nil
    end

    private

    def self.get_connection_for(options = {})
      options = {
        domain: domain,
        api_key: api_key,
        portal_key: portal_key,
        by_pass_validation: by_pass_validation,
        authorization: authorization
      }.merge(options)

      @@connections[options.hash] ||= Faraday.new(url: options[:domain]) do |faraday|
        faraday.adapter Faraday.default_adapter

        faraday.headers['X-ApiKey'] = options[:api_key]
        faraday.headers['X-PortalKey'] = options[:portal_key]
        faraday.headers['X-ByPassValidation'] = options[:by_pass_validation] if options[:by_pass_validation]
        faraday.headers['Authorization'] = options[:authorization] if options[:authorization]
      end

      @@connections[options.hash]
    end
  end

  def self.setup
    yield ConnectionManager
  end

  def self.with(options = {}, &block)
    ConnectionManager.with(options, &block)
  end

  module InstanceMethods
    def initialize(opts = {})
      opts.each do |k, v|
        associations = self.class.class_variable_get(:@@associations)
        assoc_name = k.downcase.to_sym

        if associations.key?(assoc_name)
          klass = associations[assoc_name][:class_name].constantize

          association = v.each_with_object([]) do |data, array|
            obj = klass.new
            obj.assign_attributes(data)
            array << obj
          end

          instance_variable_set("@#{k.downcase}", association)
        else
          instance_variable_set("@#{k}", v)
        end
      end
    end

    def assign_attributes(hash)
      send :initialize, hash
    end

    def populate_errors(error)
      errors.add(:api, (error.key?('Message') ? error['Message'] : error))
      if error.key?('ModelState')
        model_state = error['ModelState'].symbolize_keys!
        model_state.each do |k, v|
          next if k == self.class.name.downcase.to_sym
          v.each do |e|
            errors.add(k.to_s.split('.').last, e)
          end
        end
      end
    end

    def connection
      CrowdPay::ConnectionManager.connection
    end
  end

  module ClassMethods

    def parse(response)
      body = JSON.parse response.body

      if body.is_a? Hash
        build_object response.status, body
      else
        body.map do |attributes|
          build_object response.status, attributes
        end
      end
    end

    def build_object(status, attributes)
      obj = new

      case status
      when 200, 201
        build_hash_object obj, attributes
      when 409
        build_hash_object obj, attributes['ModelObject']
      when 400, 405, 404
        obj.populate_errors attributes
      else
        obj.errors.add(:base, "Unknown Error Status #{status}: crowd_pay.rb#parse method")
      end

      obj
    end

    def build_hash_object(obj, attributes)
      attributes = attributes.each_with_object({}) do |(k, v), hash|
        hash[k.downcase] = v
      end
      obj.assign_attributes(attributes)
    end

    def connection
      CrowdPay::ConnectionManager.connection
    end

    def get(url)
      connection.get do |req|
        req.url(url)
        req.headers['Content-Type'] = 'application/json'
      end
    end

    def post(url, data, cip_by_pass_validation = false)
      data = data.to_json unless data.is_a? String

      connection.post do |req|
        req.url(url)
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-CipByPassValidation'] = 'true' if cip_by_pass_validation
        req.body = data
      end
    end

    def put(url, data)
      data = data.to_json unless data.is_a? String

      connection.put do |req|
        req.url(url)
        req.headers['Content-Type'] = 'application/json'
        req.body = data
      end
    end

    def delete(url)
      connection.delete do |req|
        req.url(url)
        req.headers['Content-Type'] = 'application/json'
      end
    end

    private

    def register_association(assoc_name, details)
      hash = class_variable_get(:@@associations)
      class_variable_set(:@@associations, hash.merge({ assoc_name => details.symbolize_keys }.symbolize_keys))
      attr_accessor assoc_name.to_sym
    end
  end

  def self.included(base)
    base.send :include, InstanceMethods
    base.extend ClassMethods
    base.class_eval do
      cattr_reader :associations
      class_variable_set :@@associations, {}
    end
  end
end
