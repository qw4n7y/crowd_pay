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
  end

  module ClassMethods
    def create_connection
      @@connection = Faraday.new(url: domain) do |faraday|
        faraday.adapter Faraday.default_adapter

        faraday.headers['X-ApiKey'] = api_key
        faraday.headers['X-PortalKey'] = portal_key
        faraday.headers['X-ByPassValidation'] = by_pass_validation if by_pass_validation
        faraday.headers['Authorization'] = authorization if authorization
      end
    end

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
      cattr_reader :domain, :api_key, :portal_key, :connection, :associations,
        :by_pass_validation, :authorization

      class_variable_set :@@domain, ENV['CROWD_PAY_DOMAIN']
      class_variable_set :@@api_key, ENV['CROWD_PAY_API_KEY']
      class_variable_set :@@portal_key, ENV['CROWD_PAY_PORTAL_KEY']
      class_variable_set :@@by_pass_validation, ENV['CROWD_PAY_BY_PASS']
      class_variable_set :@@authorization, ENV['CROWD_PAY_AUTH']
      class_variable_set :@@associations, {}

      unless base.class_variable_get(:@@connection)
        connection = base.create_connection
        base.class_variable_set(:@@connection, connection)
      end
    end
  end
end
