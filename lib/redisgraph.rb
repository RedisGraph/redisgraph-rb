require 'redis'
require 'terminal-table'

require_relative 'redisgraph/errors.rb'
require_relative 'redisgraph/query_result.rb'
require_relative 'redisgraph/connection.rb'

class RedisGraph
  attr_accessor :connection
  attr_accessor :graphname

  # The RedisGraph constructor instantiates a Redis connection
  # and validates that the graph module is loaded
  def initialize(graph, redis_options = {})
    @graphname = graph
    connect_to_server(redis_options)
  end

  # Execute a command and return its parsed result
  def query(command)
    begin
    resp = @connection.call("GRAPH.QUERY", @graphname, command)
    rescue Redis::CommandError => e
      raise QueryError, e
    end

    QueryResult.new(resp)
  end

  # Return the execution plan for a given command
  def explain(command)
    begin
    resp = @connection.call("GRAPH.EXPLAIN", @graphname, command)
    rescue Redis::CommandError => e
      raise QueryError, e
    end
  end

  # Delete the graph and all associated keys
  def delete
    resp = @connection.call("GRAPH.DELETE", @graphname)
  end
end

