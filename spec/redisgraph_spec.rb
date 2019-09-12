require 'helper.rb'

require_relative '../lib/redisgraph.rb'

describe RedisGraph do
  # TODO it would be nice to have something like DisposableRedis
  # Connect to a Redis server on localhost:6379
  before(:all) do
    begin
      @r = RedisGraph.new("#{described_class}_test")
      create_graph
    rescue Redis::BaseError => e
      $stderr.puts(e)
    end
  end

  # Ensure that the graph "rubytest" does not exist
  after(:all) do
    @r.delete if @r
  end

  def create_graph()
    q = """CREATE (t:node {name: 'src'})"""

    res = @r.query(q)
    expect(res.resultset).to be_nil

    plan = @r.explain(q)
    expect(plan).to include("Create")

    expect(res.stats[:labels_added]).to eq(1)
    expect(res.stats[:nodes_created]).to eq(1)
    expect(res.stats[:properties_set]).to eq(1)
  end

  # Test functions - each validates one or more EXPLAIN and QUERY calls

  context "bare return" do
    it "should map values properly" do
      q = """UNWIND [1, 1.5, null, 'strval', true, false] AS a RETURN a"""
      res = @r.query(q)
      expect(res.resultset).to eq([[1], [1.5], [nil], ["strval"], [true], [false]])
    end
  end

  context "nodes" do
    it "should delete nodes properly" do
      q = """MATCH (t:node) WHERE t.name = 'src' DELETE t"""
      plan = @r.explain(q)
      expect(plan).to include("Delete")
      res = @r.query(q)
      expect(res.resultset).to be_nil
      expect(res.stats[:nodes_deleted]).to eq(1)
    end
  end

  context "edges" do
    it "should create edges properly" do
      q = "CREATE (p:node {name: 'src1', color: 'cyan'})-[:edge { weight: 7.8 }]->(:node {name: 'dest1', color: 'magenta'})," \
        " (:node {name: 'src2'})-[:edge { weight: 12 }]->(q:node_type_2 {name: 'dest2'})"
      plan = @r.explain(q)
      expect(plan).to include("Create")
      res = @r.query(q)
      expect(res.resultset).to be_nil
      expect(res.stats[:nodes_created]).to eq(4)
      expect(res.stats[:properties_set]).to eq(8)
      expect(res.stats[:relationships_created]).to eq(2)
    end

    it "should traverse edges properly" do
      q = """MATCH (a)-[e:edge]->(b:node) RETURN a.name, b, e"""
      plan = @r.explain(q)
      expect(plan.detect { |row| row.include?("Traverse") }).to_not be_nil
      res = @r.query(q)
      expect(res.columns).to eq(["a.name", "b", "e"])
      expect(res.resultset).to eq([["src1", [{"name"=>"dest1"}, {"color"=>"magenta"}], [{"weight"=>7.8}]]])
    end
  end
end
