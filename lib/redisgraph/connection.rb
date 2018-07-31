class RedisGraph
  def connect_to_server(options)
    @connection = Redis.new(options)
    self.verify_module()
  end

  # Ensure that the connected Redis server supports modules
  # and has loaded the RedisGraph module
  def verify_module()
    redis_version = @connection.info["redis_version"]
    major_version = redis_version.split('.').first.to_i
    raise ServerError, "Redis 4.0 or greater required for RedisGraph support." unless major_version >= 4
    resp = @connection.call("MODULE", "LIST")
    raise ServerError, "RedisGraph module not loaded." unless resp.first && resp.first.include?("graph")
  end
end
