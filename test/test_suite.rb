require_relative '../lib/redisgraph.rb'
require "test/unit"
include Test::Unit::Assertions

# Helper functions
# TODO it would be nice to have something like DisposableRedis

# Connect to a Redis server on localhost:6379
def connect_test
  begin
  @r = RedisGraph.new("rubytest")
  rescue Redis::BaseError => e
    puts e
    puts "RedisGraph tests require that a Redis server with the graph module loaded be running on localhost:6379"
    exit 1
  end
end

# Ensure that the graph "rubytest" does not exist
def delete_graph
  @r.delete
end

# Test functions - each validates one or more EXPLAIN and QUERY calls

def validate_node_creation
  query_str = """CREATE (t:node {name: 'src'})"""
  x = @r.query(query_str)
  plan = @r.explain(query_str)
  assert(plan =~ /Create/)
  assert(x.resultset.nil?)
  assert(x.stats[:labels_added] == 1)
  assert(x.stats[:nodes_created] == 1)
  assert(x.stats[:properties_set] == 1)
  puts "Create node - PASSED"
end

def validate_node_deletion
  query_str = """MATCH (t:node) WHERE t.name = 'src' DELETE t"""
  plan = @r.explain(query_str)
  assert(plan =~ /Delete/)
  x = @r.query(query_str)
  assert(x.resultset.nil?)
  assert(x.stats[:nodes_deleted] == 1)
  query_str = """MATCH (t:node) WHERE t.name = 'src' RETURN t"""
  assert(x.resultset.nil?)
  puts "Delete node - PASSED"
end

def validate_edge_creation
  query_str = """CREATE (p:node {name: 'src1'})-[:edge]->(:node {name: 'dest1'}), (:node {name: 'src2'})-[:edge]->(q:node_type_2 {name: 'dest2'})"""
  plan = @r.explain(query_str)
  assert(plan =~ /Create/)
  x = @r.query(query_str)
  assert(x.resultset.nil?)
  assert(x.stats[:nodes_created] == 4)
  assert(x.stats[:properties_set] == 4)
  assert(x.stats[:relationships_created] == 2)
  puts "Add edges - PASSED"
end

def validate_edge_traversal
  query_str = """MATCH (a)-[:edge]->(b:node) RETURN a, b"""
  plan = @r.explain(query_str)
  assert(plan.include?("Traverse"))
  x = @r.query(query_str)
  assert(x.resultset)
  assert(x.columns.length == 2)
  assert(x.resultset.length == 1)
  assert(x.resultset[0] == ["src1", "dest1"])
  puts "Traverse edge - PASSED"
end

def test_suite
  puts "Running RedisGraph tests..."
  connect_test
  delete_graph # Clear the graph

  # Test basic functionalities
  validate_node_creation
  validate_node_deletion
  validate_edge_creation
  validate_edge_traversal

  delete_graph # Clear the graph again
  puts "RedisGraph tests passed!"
end

test_suite
