class RedisGraph
  def connect_to_server(options)
    @connection = Redis.new(options)
    check_module_version
  end

  # Ensure that the connected Redis server supports modules
  # and has loaded the RedisGraph module
  def check_module_version()
    redis_version = @connection.info["redis_version"]
    major_version = redis_version.split('.').first.to_i
    raise ServerError, "Redis 4.0 or greater required for RedisGraph support." unless major_version >= 4

    begin
      modules = @connection.call("MODULE", "LIST")
    rescue Redis::CommandError
      # Ignore check if the connected server does not support the "MODULE LIST" command
      return
    end

    module_graph = modules.detect { |_name_key, name, _ver_key, _ver| name == 'graph' }
    module_version = module_graph[3] if module_graph
    raise ServerError, "RedisGraph module not loaded." if module_version.nil?
    raise ServerError, "RedisGraph module incompatible, expecting >= 1.99." if module_version < 19900
  end
end
