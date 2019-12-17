Gem::Specification.new do |s|
  s.name        = "rspec-httpd"
  s.version     = File.read("VERSION").chomp
  s.date        = "2019-03-01"
  s.summary     = "RSpec testing for HTTP requests"
  s.description = "RSpec testing for HTTP requests"
  s.authors     = ["Enrico Thierbach"]
  s.email       = "eno@open-lab.org"
  s.homepage    = "https://github.com/radiospiel/rspec-httpd"
  s.license     = "Nonstandard"
  s.files       = `git ls-files`.split.grep(%r{README|VERSION|lib/})

  # Runtime dependencies of this gem:
  s.add_dependency "expectation", "~> 1.1.1"
  s.add_dependency "simple-http", "~> 0.3.2"

  # Gems for dev and test env:
  s.add_development_dependency "rake",        "~> 12.0"
  s.add_development_dependency "rspec",       "~> 3.4"
  s.add_development_dependency "rubocop",     "~> 0.65.0"
end
