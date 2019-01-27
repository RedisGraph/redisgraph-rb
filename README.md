[![license](https://img.shields.io/github/license/RedisGraph/redisgraph-rb.svg)](https://github.com/RedisGraph/redisgraph-rb)
[![CircleCI](https://circleci.com/gh/RedisGraph/redisgraph-rb/tree/master.svg?style=svg)](https://circleci.com/gh/RedisGraph/redisgraph-rb/tree/master)
[![GitHub issues](https://img.shields.io/github/release/RedisGraph/redisgraph-rb.svg)](https://github.com/RedisGraph/redisgraph-rb/releases/latest)


# redisgraph-rb

`redisgraph-rb` is a Ruby gem client for the [RedisGraph](https://github.com/RedisLabsModules/RedisGraph) module. It relies on `redis-rb` for Redis connection management and provides support for graph QUERY, EXPLAIN, and DELETE commands.

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
A simple test suite is provided, and can be run with:
`ruby test/test_suite.rb`
These tests expect a Redis server with the Graph module loaded to be available at localhost:6379

