require 'redis'
require 'terminal-table'

require_relative 'redisgraph/errors.rb'
require_relative 'redisgraph/query_result.rb'
require_relative 'redisgraph/connection.rb'

class RedisGraph
  attr_accessor :connection
  attr_accessor :graphname
  attr_accessor :metadata

  class Metadata
    def initialize(opts = {})
      @graphname = opts[:graphname]
      @connection = opts[:connection]

      # cache semantics around these labels, propertyKeys, and relationshipTypes
      # defers first read and is invalidated when changed.
      @labels_proc =  -> { call_procedure('db.labels') }
      @property_keys_proc = -> { call_procedure('db.propertyKeys') }
      @relationship_types_proc = -> { call_procedure('db.relationshipTypes') }
    end

    def invalidate
      @labels = @property_keys = @relationship_types = nil
    end

    def labels
      @labels ||= @labels_proc.call
    end

    def property_keys
      @property_keys ||= @property_keys_proc.call
    end

    def relationship_types
      @relationship_types ||= @relationship_types_proc.call
    end

    def call_procedure(procedure)
      res = @connection.call("GRAPH.QUERY", @graphname, "CALL #{procedure}()")
      res[1].flatten
    rescue Redis::CommandError => e
      raise CallError, e
    end
  end

  # The RedisGraph constructor instantiates a Redis connection
  # and validates that the graph module is loaded
  def initialize(graph, redis_options = {})
    @graphname = graph
    connect_to_server(redis_options)
    @metadata = Metadata.new(graphname: @graphname,
                             connection: @connection)
  end

  # Execute a command and return its parsed result
  def query(command)
    resp = @connection.call('GRAPH.QUERY', @graphname, command, '--compact')
    QueryResult.new(resp,
                    metadata:   @metadata)
  rescue Redis::CommandError => e
    raise QueryError, e
  end

  # Return the execution plan for a given command
  def explain(command)
    @connection.call('GRAPH.EXPLAIN', @graphname, command)
  rescue Redis::CommandError => e
    raise ExplainError, e
  end

  # Delete the graph and all associated keys
  def delete
    @connection.call('GRAPH.DELETE', @graphname)
  rescue Redis::CommandError => e
    raise DeleteError, e
  end
end
