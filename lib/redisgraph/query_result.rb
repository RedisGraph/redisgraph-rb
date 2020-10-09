# frozen_string_literal: true

# Data types that can be returned in result sets
module ValueType
  UNKNOWN = 0
  NULL = 1
  STRING = 2
  INTEGER = 3
  BOOLEAN = 4
  DOUBLE = 5
  ARRAY = 6
  EDGE = 7
  NODE = 8
  PATH = 9 # TODO: not yet implemented
end

class QueryResult
  attr_accessor :columns
  attr_accessor :resultset
  attr_accessor :stats

  def initialize(response, opts = {})
    # The response for any query is expected to be a nested array.
    # If compact (RedisGraph protocol v2)
    # The resultset is an array w/ three elements:
    # 0] Node/Edge key names w/ the ordinal position used in [1]
    #    en lieu of the name to compact the result set.
    # 1] Node/Edge key/value pairs as an array w/ two elements:
    #  0] node/edge name id from [0]
    #  1..matches] node/edge values
    # 2] Statistics as an array of strings

    @metadata = opts[:metadata]

    @resultset = parse_resultset(response)
    @stats = parse_stats(response)
  end

  def print_resultset
    return unless columns

    pretty = Terminal::Table.new headings: columns do |t|
      resultset.each { |record| t << record }
    end
    puts pretty
  end

  def parse_resultset(response)
    # In the v2 protocol, CREATE does not contain an empty row preceding statistics
    return unless response.length > 1

    # Any non-empty result set will have multiple rows (arrays)

    # First row is header describing the returned records, corresponding
    # precisely in order and naming to the RETURN clause of the query.
    header = response[0]
    @columns = header.map { |(_type, name)| name }

    # Second row is the actual data returned by the query
    # note handling for encountering an id for propertyKey that is out of
    # the cached set.
    data = response[1].map do |row|
      i = -1
      header.reduce([]) do |agg, (type, _it)|
        i += 1
        el = row[i]
        case type
        when 1 # Column of scalars
          agg << map_scalar(el[0], el[1])
        when 2 # node
          props = el[2]
          agg << props.sort_by { |prop| prop[0] }.map { |prop| map_prop(prop) }
        when 3 # Column of relations
          props = el[4]
          agg << props.sort_by { |prop| prop[0] }.map { |prop| map_prop(prop) }
        end
      end
    end

    data
  end

  def map_scalar(type, val)
    map_func = case type
               when ValueType::NULL
                 return nil
               when ValueType::STRING
                 :to_s
               when ValueType::INTEGER
                 :to_i
               when ValueType::BOOLEAN
                 # no :to_b
                 return val == 'true'
               when ValueType::DOUBLE
                 :to_f
               when ValueType::ARRAY
                 return val.map { |it| map_scalar(it[0], it[1]) }
               when ValueType::EDGE
                 props = val[4]
                 return props.sort_by { |prop| prop[0] }.map { |prop| map_prop(prop) }
               when ValueType::NODE
                 props = val[2]
                 return props.sort_by { |prop| prop[0] }.map { |prop| map_prop(prop) }
               end
    val.send(map_func)
  end

  def map_prop(prop)
    # maximally a single @metadata.invalidate should occur

    property_keys = @metadata.property_keys
    prop_index = prop[0]
    if prop_index >= property_keys.length
      @metadata.invalidate
      property_keys = @metadata.property_keys
    end
    { property_keys[prop_index] => map_scalar(prop[1], prop[2]) }
  end

  # Read metrics about internal query handling
  def parse_stats(response)
    # In the v2 protocol, CREATE does not contain an empty row preceding statistics
    stats_offset = response.length == 1 ? 0 : 2

    return nil unless response[stats_offset]

    parse_stats_row(response[stats_offset])
  end

  def parse_stats_row(response_row)
    stats = {}

    response_row.each do |stat|
      line = stat.split(': ')
      val = line[1].split(' ')[0].to_i

      case line[0]
      when /^Labels added/
        stats[:labels_added] = val
      when /^Nodes created/
        stats[:nodes_created] = val
      when /^Nodes deleted/
        stats[:nodes_deleted] = val
      when /^Relationships deleted/
        stats[:relationships_deleted] = val
      when /^Properties set/
        stats[:properties_set] = val
      when /^Relationships created/
        stats[:relationships_created] = val
      when /^Query internal execution time/
        stats[:internal_execution_time] = val
      end
    end
    stats
  end
end
