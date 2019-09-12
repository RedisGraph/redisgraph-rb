[![license](https://img.shields.io/github/license/RedisGraph/redisgraph-rb.svg)](https://github.com/RedisGraph/redisgraph-rb)
[![CircleCI](https://circleci.com/gh/RedisGraph/redisgraph-rb/tree/master.svg?style=svg)](https://circleci.com/gh/RedisGraph/redisgraph-rb/tree/master)
[![GitHub issues](https://img.shields.io/github/release/RedisGraph/redisgraph-rb.svg)](https://github.com/RedisGraph/redisgraph-rb/releases/latest)
[![Codecov](https://codecov.io/gh/RedisGraph/redisgraph-rb/branch/master/graph/badge.svg)](https://codecov.io/gh/RedisGraph/redisgraph-rb)


# redisgraph-rb

`redisgraph-rb` is a Ruby gem client for the [RedisGraph](https://github.com/RedisLabsModules/RedisGraph) module. It relies on `redis-rb` for Redis connection management and provides support for graph QUERY, EXPLAIN, and DELETE commands.

## RedisGraph compatibility
The current version of `redisgraph-rb` is compatible with RedisGraph versions >= 1.99 (module version: 19900).

### Previous Version
For RedisGraph versions >= 1.0 and < 2.0 (ie module version: 10202), instead use and refer to
the redisgraph gem version ~> 1.0.0

which corresponds to the following docker image
`docker run -p 6379:6379 -it --rm redislabs/redisgraph:1.2.2`

## Installation
To install, run:

`$ gem install redisgraph`

Or include `redisgraph` as a dependency in your Gemfile.

## Usage
```
require 'redisgraph'

graphname = "sample"

r = RedisGraph.new(graphname)

cmd = """CREATE (:person {name: 'Jim', age: 29})-[:works]->(:employer {name: 'Dunder Mifflin'})"""
response = r.query(cmd)
response.stats
 => {:labels_added=>2, :nodes_created=>2, :properties_set=>3, :relationships_created=>1, :internal_execution_time=>0.705541}

cmd = """MATCH ()-[:works]->(e:employer) RETURN e"""

response = r.query(cmd)

response.print_resultset
+----------------+
| e.name         |
+----------------+
| Dunder Mifflin |
+----------------+

r.delete
 => "Graph removed, internal execution time: 0.416024 milliseconds"
```

## Specifying Redis options
RedisGraph connects to an active Redis server, defaulting to `host: localhost, port: 6379`. To provide custom connection parameters, instantiate a RedisGraph object with a `redis_options` hash:

`r = RedisGraph.new("graphname", redis_options= { host: "127.0.0.1", port: 26380 })`

These parameters are described fully in the documentation for https://github.com/redis/redis-rb

## Running tests
To ensure prerequisites are installed, run the following:
`bundle install`

These tests expect a Redis server with the Graph module loaded to be available at localhost:6379

The currently compatible version of the RedisGraph module may be run as follows:
`docker run -p 6379:6379 -it --rm redislabs/redisgraph:2.0-edge`

A simple test suite is provided, and can be run with:
`rspec`
