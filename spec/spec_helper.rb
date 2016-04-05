require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'factory_girl'
require 'webmock/rspec'
require 'active_support/time'

require 'crowd_pay'

CrowdPay.setup do |config|
  config.domain = 'https://test.crowdpay.com'
  config.api_key = 'test'
  config.portal_key = 'test'
end

WebMock.disable_net_connect!(:allow => "codeclimate.com")

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end
end
