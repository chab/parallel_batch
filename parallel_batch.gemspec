# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Alexis Bernard"]
  gem.email         = ["alexis@official.com"]
  gem.description   = "Run safely concurent batches"
  gem.summary       = "Run safely concurent batches"
  gem.homepage      = "https://github.com/officialfm/parallel_batch"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "parallel_batch"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.2"
end
