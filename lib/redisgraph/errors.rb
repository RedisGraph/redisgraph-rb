class RedisGraph
  class RedisGraphError < RuntimeError
  end

  class ServerError < RedisGraphError
  end

  class QueryError < RedisGraphError
  end
end
