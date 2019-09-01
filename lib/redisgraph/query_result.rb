class QueryResult
  attr_accessor :columns
  attr_accessor :resultset
  attr_accessor :stats

  def initialize(response, opts = {})
    # The response for any query is expected to be a nested array.
    # If not compact (RedisGraph protocol v1)
    # The resultset is an array w/ two elements:
    # 0] Node/Edge key/value pairs as an array w/ two elements:
    #  0] node/edge names
    #  1..matches] node/edge values
    # 1] Statistics as an array of strings
    #
    # If compact (RedisGraph protocol v2)
    # The resultset is an array w/ three elements:
    # 0] Node/Edge key names w/ the ordinal position used in [1]
    #    en lieu of the name to compact the result set.
    # 1] Node/Edge key/value pairs as an array w/ two elements:
    #  0] node/edge name id from [0]
    #  1..matches] node/edge values
    # 2] Statistics as an array of strings
    #
    @compact = opts[:compact]
    @query_type = opts[:query_type]
    @graph = opts[:graph]

    @resultset = parse_resultset(response)
    @stats = parse_stats(response)
  end

  def print_resultset
    pretty = Terminal::Table.new headings: columns do |t|
      resultset.each { |record| t << record }
    end
    puts pretty
  end

  def parse_resultset(response)
    meth = @compact ? :parse_resultset_v2 : :parse_resultset_v1
    send(meth, response)
  end

  def parse_resultset_v1(response)
    # Any non-empty result set will have multiple rows (arrays)
    return nil unless response[0].length > 1
    # First row is return elements / properties
    @columns = response[0].shift
    # Subsequent rows are records
    @resultset = response[0]
  end

  def parse_resultset_v2(response)
    # In the v2 protocol, CREATE does not contain an empty row preceding statistics
    case @query_type
    when :create, :delete
      return
    end

    # Any non-empty result set will have multiple rows (arrays)
    return nil unless response[0].length > 1

    property_keys = @graph.property_keys

    # First row is header describing the returned records, corresponding
    # precisely in order and naming to the RETURN clause of the query.
    header = response[0].map { |_type, el| el }.to_a

    @columns = header.reduce([]) do |agg, it|
      if it.include?('.')
        agg << it
      else
        property_keys.each do |pkey|
          agg << "#{it}.#{pkey}"
        end
      end
      agg
    end

    # TODO: add handling for encountering an id for propertyKey that is out of
    # the cached set. this currently works for the test cases and generally for
    # A. a single client, on changing the schema the cache is invalidated.
    # B. a graph that has the schema relatively static, so cache remains coherent

    # Second row is the actual data returned by the query
    data = response[1].map do |row|
      src, dest = row
      src_props = src[2].sort_by { |it| it[0] }.map { |props| props[2] }
      dest_props = dest[2].sort_by { |it| it[0] }.map { |props| props[2] }
      src_props + dest_props
    end

    data
  end

  # Read metrics about internal query handling
  def parse_stats(response)
    meth = @compact ? :parse_stats_v2 : :parse_stats_v1
    send(meth, response)
  end

  def parse_stats_v2(response)
    # In the v2 protocol, CREATE does not contain an empty row preceding statistics
    stats_offset = case @query_type
                when :create, :delete then 0
                when :match then 2
                end

    return nil unless response[stats_offset]

    parse_stats_row(response[stats_offset])
  end

  def parse_stats_v1(response)
    return nil unless response[1]

    parse_stats_row(response[1])
  end

  def parse_stats_row(response_row)
    stats = {}

    response_row.each do |stat|
      line = stat.split(': ')
      val = line[1].split(' ')[0]

      case line[0]
      when /^Labels added/
        stats[:labels_added] = val.to_i
      when /^Nodes created/
        stats[:nodes_created] = val.to_i
      when /^Nodes deleted/
        stats[:nodes_deleted] = val.to_i
      when /^Relationships deleted/
        stats[:relationships_deleted] = val.to_i
      when /^Properties set/
        stats[:properties_set] = val.to_i
      when /^Relationships created/
        stats[:relationships_created] = val.to_i
      when /^Query internal execution time/
        stats[:internal_execution_time] = val.to_f
      end
    end
    stats
  end
end
