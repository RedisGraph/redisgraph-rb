class RedisGraph
  class RedisGraphError < RuntimeError; end

  class ServerError < RedisGraphError; end

  class CallError < RedisGraphError; end
  class QueryError < RedisGraphError; end
  class ExplainError < RedisGraphError; end
  class DeleteError < RedisGraphError; end
end
