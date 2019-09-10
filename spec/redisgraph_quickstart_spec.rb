require 'helper.rb'

require_relative '../lib/redisgraph.rb'

# based on queries extracted from
describe RedisGraph do
  before(:all) do
    @r = RedisGraph.new("#{described_class}_test")
    create_graph
  rescue Redis::BaseError => e
    $stderr.puts(e)
    exit 1
  end

  after(:all) do
    @r.delete if @r
  end

  def create_graph()
    q = "CREATE (:Rider {name:'Valentino Rossi'})-[:rides]->(:Team {name:'Yamaha'})," \
      "(:Rider {name:'Dani Pedrosa'})-[:rides]->(:Team {name:'Honda'})," \
      "(:Rider {name:'Andrea Dovizioso'})-[:rides]->(:Team {name:'Ducati'})"

    res = @r.query(q)

    expect(res.resultset).to be_nil
    stats = res.stats
    expect(stats).to include(:internal_execution_time)
    stats.delete(:internal_execution_time)
    expect(stats).to eq({
      labels_added:          2,
      nodes_created:         6,
      properties_set:        6,
      relationships_created: 3
    })
  end

  context 'quickstart' do
    it 'should query relations, with a predicate' do
      q = "MATCH (r:Rider)-[:rides]->(t:Team) WHERE t.name = 'Yamaha' RETURN r.name, t.name"

      res = @r.query(q)

      expect(res.columns).to eq(["r.name", "t.name"])
      expect(res.resultset).to eq([["Valentino Rossi", "Yamaha"]])
    end

    # not in the quickstart, but demonstrates multiple rows
    it 'should query relations, without a predicate' do
      q = "MATCH (r:Rider)-[:rides]->(t:Team) RETURN r.name, t.name ORDER BY r.name"

      res = @r.query(q)

      expect(res.columns).to eq(["r.name", "t.name"])
      expect(res.resultset).to eq([
        ["Andrea Dovizioso", "Ducati"],
        ["Dani Pedrosa", "Honda"],
        ["Valentino Rossi", "Yamaha"]
      ])
    end

    it 'should query relations, with an aggregate function' do
      q = "MATCH (r:Rider)-[:rides]->(t:Team {name:'Ducati'}) RETURN count(r)"

      res = @r.query(q)

      expect(res.columns).to eq(["count(r)"])
      expect(res.resultset).to eq([[1]])
    end
  end
end
