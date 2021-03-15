require "./lib/redisgraph/version"

Gem::Specification.new do |s|
  s.name = "redisgraph"

  s.version = RedisGraph::VERSION

  s.license = 'BSD-3-Clause'

  s.homepage = 'https://github.com/redislabs/redisgraph-rb'

  s.summary = 'A client for RedisGraph'

  s.description = 'A client that extends redis-rb to provide explicit support for the RedisGraph module.'

  s.authors = ['Redis Labs']

  s.email = 'jeffrey@redislabs.com'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency('redis', '~> 4')
end
