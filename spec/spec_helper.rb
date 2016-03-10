require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'factory_girl'
require 'webmock/rspec'
require 'active_support/time'

require 'crowd_pay'

ENV['CROWD_PAY_DOMAIN'] = 'https://test.crowdpay.com'
ENV['CROWD_PAY_API_KEY'] = 'test'
ENV['CROWD_PAY_PORTAL_KEY'] = 'test'
ENV['CROWD_PAY_BY_PASS'] = 'test'

WebMock.disable_net_connect!(:allow => "codeclimate.com")

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end
end
