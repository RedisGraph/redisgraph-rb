class QueryResult
  attr_accessor :columns
  attr_accessor :resultset
  attr_accessor :stats

  def print_resultset
    pretty = Terminal::Table.new headings: columns do |t|
      resultset.each { |record| t << record }
    end
    puts pretty
  end

  def parse_resultset(response)
    # Any non-empty result set will have multiple rows (arrays)
    return nil unless response[0].length > 1
    # First row is return elements / properties
    @columns = response[0].shift
    # Subsequent rows are records
    @resultset = response[0]
  end

  # Read metrics about internal query handling
  def parse_stats(response)
    return nil unless response[1]

    stats = {}

    response[1].each do |stat|
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

  def initialize(response)
    # The response for any query is expected to be a nested array.
    # The only top-level values will be the result set and the statistics.
    @resultset = parse_resultset(response)
    @stats = parse_stats(response)
  end
end

