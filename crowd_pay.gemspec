require File.expand_path('../lib/crowd_pay/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'crowd_pay'
  gem.version     = CrowdPay::VERSION
  gem.date        = '2016-02-23'
  gem.summary     = 'A ruby client for the CrowdPay API using ActiveModel'
  gem.description = 'A ruby client for CrowdPay\'s API using ActiveModel for easy to use ruby objects.' \
                    'This gem has been extracted from the Vested.org project courtesy of Calvert Foundation.'
  gem.authors     = ['Kelton Manzanares', 'Prakash Lingaiah', 'Krishnaprasad Varma']
  gem.email       = ['kelton.manzanares@gmail.com', 'plingaiah@qwinix.io', 'kvarma@qwinix.io']
  gem.files       = `git ls-files`.split($\)
  gem.homepage    = 'https://github.com/qwinix/crowd_pay'
  gem.license     = 'MIT'

  gem.add_runtime_dependency 'activemodel'
  gem.add_runtime_dependency 'faraday', '~> 0.9'
end
