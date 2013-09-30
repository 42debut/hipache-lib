
redis = require 'redis'
Q     = require 'q'

require("mocha-as-promised")()

chai = require 'chai'
chai.use require("chai-as-promised")
assert = chai.assert
expect = chai.expect
should = chai.should()


describe 'HipacheLib', ->
    {Hipache} = require '../lib/hipache'
    FRONTEND_KEY = 'HipacheTest'

    cleanupRedis = do ->
        redis = redis.createClient()

        redisDel = (key) ->
            deferred = Q.defer()
            redis.del key, (err) ->
                return deferred.reject err if err
                return deferred.resolve()
            return deferred.promise

        return ->
            deferred = Q.defer()
            redis.keys "#{FRONTEND_KEY}:*", (err, keys) ->
                return deferred.reject err if err
                console.log "Cleaning up keys:", keys
                Q.all(keys.map redisDel).then -> deferred.resolve()
            return deferred.promise


    before ->
        console.log "Before tests:"
        cleanupRedis()

    after ->
        console.log "After tests:"
        cleanupRedis()

    hipache = new Hipache frontendKey:FRONTEND_KEY

    describe '#getRoute', ->

        it 'should throw exception on invalid input.', ->
            should.Throw -> hipache.getRoute()
            should.Throw -> hipache.getRoute ''
            should.Throw -> hipache.getRoute []
            should.Throw -> hipache.getRoute {}

        it 'should return null if host is not found.', ->
            hipache.getRoute('foo.bar').should.become null


    describe '#createRoute', ->

        it 'should throw exception on invalid input', ->
            should.Throw -> hipache.createRoute()
            should.Throw -> hipache.createRoute ''
            should.Throw -> hipache.createRoute {}
            should.Throw -> hipache.createRoute []
            should.Throw -> hipache.createRoute '42', 42
            should.Throw -> hipache.createRoute '42', {}
            should.Throw -> hipache.createRoute '42', ''

    describe '#getRoutes', ->

        it 'should return an empty list', ->
            hipache.getRoutes().should.become []


    describe '#updateRoute', ->

        it 'should throw exception on invalid input', ->
            should.Throw -> hipache.updateRoute()
            should.Throw -> hipache.updateRoute ''
            should.Throw -> hipache.updateRoute []
            should.Throw -> hipache.updateRoute {}
            should.Throw -> hipache.createRoute '42', 42
            should.Throw -> hipache.createRoute '42', {}
            should.Throw -> hipache.createRoute '42', ''

        it 'should fail when trying to update missing route `lol.sup`', ->
            hipache.updateRoute('lol.sup', []).should.be.rejected


    describe '#deleteRoute', ->

        it 'should throw exception on invalid input', ->
            should.Throw -> hipache.deleteRoute()
            should.Throw -> hipache.deleteRoute ''
            should.Throw -> hipache.deleteRoute []
            should.Throw -> hipache.deleteRoute {}

    describe '#hasRoute', ->

        it 'should throw exception on invalid input', ->
            should.Throw -> hipache.hasRoute()
            should.Throw -> hipache.hasRoute ''
            should.Throw -> hipache.hasRoute []
            should.Throw -> hipache.hasRoute {}

        it 'should not find the `lol.sup` route', ->
            hipache.hasRoute('lol.sup').should.become false


    describe 'CRUD flows', ->

        before ->
            cleanupRedis()

        fooBarRoute =
            id: 'foo.bar'
            backends: ['http://localhost:7000']

        lolSupRoute =
            id: 'lol.sup'
            backends: ['http://localhost:7000']


        it "should create the `#{fooBarRoute.id}` route", ->
            hipache.createRoute(fooBarRoute.id, fooBarRoute.backends).should.be.fulfilled
        it "should find the `#{fooBarRoute.id}` route", ->
            hipache.hasRoute(fooBarRoute.id).should.become true
        it "should get the `#{fooBarRoute.id}` route", ->
            hipache.getRoute(fooBarRoute.id).should.become fooBarRoute
        it "should fail when trying to create the same route", ->
            hipache.createRoute(fooBarRoute.id).should.be.rejected

        it "should update the `#{fooBarRoute.id}` route", ->
            fooBarRoute.backends.push 'http://localhost:8000'
            hipache.updateRoute(fooBarRoute.id, fooBarRoute.backends).should.be.fulfilled
        it "should find the `#{fooBarRoute.id}` route", ->
            hipache.hasRoute(fooBarRoute.id).should.become true
        it "should get the `#{fooBarRoute.id}` route", ->
            hipache.getRoute(fooBarRoute.id).should.become fooBarRoute
        it "should get all routes, which only has the `#{fooBarRoute.id}` route", ->
            hipache.getRoutes().should.become [fooBarRoute]

        it "should create the `#{lolSupRoute.id}` route, using the `updateRoute` method", ->
            hipache.updateRoute(lolSupRoute.id, lolSupRoute.backends, true).should.be.fulfilled
        it "should find the `#{lolSupRoute.id}` route", ->
            hipache.hasRoute(lolSupRoute.id).should.become true
        it "should get the `#{lolSupRoute.id}` route", ->
            hipache.getRoute(lolSupRoute.id).should.become lolSupRoute

        it "should get all routes", ->
            hipache.getRoutes().should.become [fooBarRoute, lolSupRoute]

        it "should delete the `#{fooBarRoute.id}` route", ->
            hipache.deleteRoute(fooBarRoute.id).should.be.fulfilled
        it "should not find the `#{fooBarRoute.id}` route", ->
            hipache.hasRoute(fooBarRoute.id).should.become false
        it "should get all routes, which only has the `#{lolSupRoute.id}` route", ->
            hipache.getRoutes().should.become [lolSupRoute]

        it "should delete the `#{lolSupRoute.id}` route", ->
            hipache.deleteRoute(lolSupRoute.id).should.be.fulfilled
        it 'should get all routes, i.e. an empty list', ->
            hipache.getRoutes().should.become []