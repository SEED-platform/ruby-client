lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seed/version'

Gem::Specification.new do |spec|
  spec.name          = 'seed_ruby_client'
  spec.version       = Seed::VERSION
  spec.authors       = ['Nicholas Long']
  spec.email         = ['nicholas.long@nrel.gov']

  spec.summary       = 'Ruby Client for communicating with SEED API'
  spec.description   = 'Ruby Client for communicating with SEED API'
  spec.homepage      = 'https://seed-platform.org'

  spec.platform      = Gem::Platform::RUBY

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.platform      = Gem::Platform::RUBY

  spec.add_runtime_dependency 'unf'
  spec.add_runtime_dependency 'rest-client', '~> 2.1'
  spec.add_development_dependency 'bundler', '~> 2.3'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
end
