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

    if call_compact?
      # when call_compact?, labels will be compressed, so require a lookup
      # table maintained on the client

      # cache semantics around these labels, propertyKeys, and relationshipTypes
      # defers first read and is invalidated when changed.
      @labels_proc =  -> { call_procedure('db.labels') }
      @property_keys_proc = -> { call_procedure('db.propertyKeys') }
      @relationship_types_proc = -> { call_procedure('db.relationshipTypes') }
    end
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

  # Execute a command and return its parsed result
  def query(command)
    resp = @connection.call("GRAPH.QUERY", @graphname, command, \
                            call_compact? ? '--compact' : '')
    qtype = query_type(command)
    rs = QueryResult.new(resp,
                         compact:    call_compact?,
                         query_type: qtype,
                         graph:      self)
    case qtype
    when :create, :delete
      @labels = @property_keys = @relationship_types = nil
    end

    rs
  rescue Redis::CommandError => e
    raise QueryError, e
  end

  def query_type(command)
    command_parts = command.split(' ')
    qtype = command_parts[0].downcase.to_sym

    case qtype
    when :create, :match
    else
      raise QueryError, "Unexpected query type: #{qtype}, supported: CREATE, MATCH"
    end
    
    if qtype == :match
      if command_parts.detect { |part| part.downcase.to_sym == :delete }
        qtype = :delete
      end
    end

    qtype
  end

  # Return the execution plan for a given command
  def explain(command)
    resp = @connection.call("GRAPH.EXPLAIN", @graphname, command)
    resp = call_compact? ? resp : resp.split("\n")
  rescue Redis::CommandError => e
    raise ExplainError, e
  end

  # Delete the graph and all associated keys
  def delete
    @connection.call("GRAPH.DELETE", @graphname)
  rescue Redis::CommandError => e
    raise DeleteError, e
  end

  def call_procedure(procedure)
    res = @connection.call("GRAPH.QUERY", @graphname, "CALL #{procedure}()")
    res[1].flatten
  rescue Redis::CommandError => e
    raise CallError, e
  end
end
