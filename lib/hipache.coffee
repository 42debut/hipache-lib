
_    = require 'lodash'
Q    = require 'Q'

class exports.Hipache

    @DEFAULT_FRONTEND_KEY:'frontend'


    # Options
    # - frontendKey: the key used to find a frontend, defaults to `frontend`.
    # - redis: object, see `_createRedisClient` options
    constructor: (@options = {}) ->
        @options.frontendKey ?= HipacheBackend::DEFAULT_FRONTEND_KEY
        @redis = @_createRedisClient @options.redis


    createRoute: (host, backends = []) ->
        host     = @_validateHost host
        backends = @_validateBackends backends
        @hasRoute(host).then (hasRoute) =>
            throw new Error "Route `#{host}` already exists." if hasRoute
            deferred = Q.defer()
            values = [host].concat backends
            @redis.rpush (@_key host), values..., (err, res) ->
                return deferred.reject if err
                return deferred.resolve (new HipacheRoute {id:host, backends})
            return deferred.promise


    getRoutes: ->
        deferred = Q.defer()
        @redis.keys (@_key '*'), (err, routes) =>
            return deferred.reject err if err
            routes = routes.map (r) => r.replace @_key(), ""
            Q.all(routes.map (r) => @getRoute r).then (routes) ->
                deferred.resolve routes
        return deferred.promise


    getRoute: (host) ->
        host = @_validateHost host
        deferred = Q.defer()
        @redis.lrange (@_key host), 0, -1, (err, results) ->
            return deferred.reject err if err
            return deferred.resolve do ->
                return null if not results or results.length < 1
                [id, backends...] = results
                return new HipacheRoute {id, backends:(backends or [])}
        return deferred.promise


    updateRoute: (host, backends = [], create = false) ->
        host = @_validateHost host
        backends = @_validateBackends backends
        update = => @deleteRoute(host).then => @createRoute host, backends
        return update() if create
        @hasRoute(host).then (hasRoute) ->
            return update() if hasRoute
            throw new Error 'Cannot update `host`; route does not exist'


    deleteRoute: (host) ->
        host = @_validateHost host
        deferred = Q.defer()
        @redis.del @_key(host), (err) ->
            return deferred.reject err if err
            return deferred.resolve()
        return deferred.promise


    hasRoute: (host) ->
        @getRoute(host).then (route) -> Boolean route


    _validateHost: (host) ->
        if not host
            throw new Error "`host` argument is required."
        if not ((_.isString host) or (_.isNumber host))
            throw new Error '`host` argument must be of type `String` or `Number`.'
        return host.toString()


    _validateBackends: (backends) ->
        if not backends
            throw new Error '`backends` argument is required.'
        if not ((_.isArray backends) or (_.isString backends))
            throw new Error '`backends` argument must be of type `String` or `Array`.'
        if _.isString backends and backends.length is 0
            throw new Error '`backends` argument cannot be an empty string.'
        return if _.isString backends then [backends] else backends


    _key: (key = '') ->
        "#{@options.frontendKey}:#{key}"


    # Options
    # - host: redis host
    # - port: redis port
    # - options: various redis config options
    _createRedisClient: (redisOptions = {}) ->
        redis = require 'redis'
        redis.createClient redisOptions?.port, redisOptions?.host, redisOptions.options


class HipacheRoute
    constructor: (id, backends) ->
        {@id, @backends} = do ->
            return {id, backends} if arguments.length is 2
            return id
