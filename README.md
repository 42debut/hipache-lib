# Hipache Lib

A library to configure hipache (via redis).

[![Build Status](https://api.travis-ci.org/42debut/hipache-lib.png)](https://travis-ci.org/42debut/hipache-lib)


# API


## constructor(options)

##### `options` object

| key         | type   | required | value
| ----------- | ------ | -------- | -------------------------------------------------------------------------
| frontendKey | String | false    | The first part of the frontend keys: `#{fontendKey}:<host>`. Defaults to `frontend`.
| redis       | Object | false    | Options to configure the redis client

##### `redis` object
| key         | type    | required | value
| ----------- | ------- | -------- | ----------------------------------------
| host        | String  | false    | The redis host. Defaults to `localhost`.
| redis       | Integer | false    | The redis port. Defaults to `6379`.
| options     | Object  | false    | Options to pass to the redis client.


## createRoute(host, backends = [])

Creates a route. Returns a promise that resolves to a `HipacheRoute` object.

| argument    | type              | required | description
| ----------- | ----------------- | -------- | ------------------------------------------------------
| host        | String or Integer | **true** | The host/url to match an incoming request.
| backends    | String or Array   | false    | The backends to redirect the incoming request. Defaults to `[]`.


## getRoutes()

Get all the routes. Returns a promise that resolves to an `Array` of `HipacheRoute` objects.


## getRoute(host)

Get a specific route. Returns a promise that resolves to a `HipacheRoute` object if the
route exists, or `null` if it doesn't.

| argument    | type              | required | description
| ----------- | ----------------- | -------- | ------------------------------
| host        | String or Integer | **true** | The host/id of the route you want to get.


## updateRoute(host, backends = [], create = false)

Update a specific route.

> This method first deletes the route, and then creates a new one. This means that there is a risk
> of a race condition if something else is modifying the hipache redis config at the same time.

| argument   | type              | required | description
| ---------- | ----------------- | -------- | -----------------------------------------------------
| host       | String or Integer | **true** | The host/url to update.
| backends   | String or Array   | false    | The new list of backends. Defaults to `[]`.
| create     | Boolean           | false    | Create the route if it doesn't exist. Defaults to `false`.


## deleteRoute(host)

Delete a specific route.

> This method doesn't check if the route exists.

| argument    | type              | required | description
| ----------- | ----------------- | -------- | -----------------------------------------------------
| host        | String or Integer | **true** | The host/url to delete.


## hasRoute(host)

Check if a route exists.

> This method uses the `Hipache#getRoute` method internally.

| argument    | type              | required | description
| ----------- | ----------------- | -------- | -----------------------------------------------------
| host        | String or Integer | **true** | The host/url to check.


# Testing

Simply run `npm test`.


# License

The MIT License (MIT)

Copyright (c) 2013 42 Technologies Inc.
