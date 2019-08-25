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
    modules = @connection.call("MODULE", "LIST")
    module_graph = modules.detect { |_name_key, name, _ver_key, _ver| name == 'graph' }
    raise ServerError, "RedisGraph module not loaded." if module_graph.nil?
  end
end
