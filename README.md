# crush

A time-traveling, replicated, eventually-consistent key-value store.

## Warning

**Operations are currently NOT atomic!** Writing to a key concurrently can and
likely **will** cause issues. You have been warned!

## API

### `GET /:key`

Returns the key and its revisions. The returned value looks like:

```Javascript
[current_value, revisions]
```
where `revisions` is a possibly-empty list.

If the key does not exist, an empty list is returned:

```Javascript
[]
```

#### Query parameters

- `revisions`: The number of revisions to return. Set to `all` for all
  revisions. If this value is not specified, or is not a number or the literal
  string `"all"`, an empty list of revisions will be returned.
- `patch`: Whether or not to apply patches. By default, the returned revisions
  are a set of patches that can be used to revert to each previous state. If
  `patch` is set to `true`, the patches will be applied, and the computed
  values will be returned as the list of revisions. Defaults to `false`.

### `GET /:key/info`

Returns info about the given key.

```js
// ▶  curl localhost:7654/test/info
{"key":"test","revision_count":11}
```

### `PUT /:key`

Sets the value at the given key. The request body is the value that is set.
Returns the value that was set.

### `DELETE /:key`

Deletes the key from the store. Returns the following JSON:
```js
{
  "status": "ok",
}
```

### Forks

All of these routes take a `:fork` parameter, like this:

```
GET /:key/:fork
PUT /:key/:fork
DELETE /:key/:fork
GET /:key/:fork/info
```

If you don't provide a fork, the default fork is used.

### Forking keys

You can fork a key to operate on a copy of its data without affecting the
original. Likewise, you can merge a fork into a target fork.

#### `POST /:key/:fork/fork/:target`

```js
// On success
{
  "status": "ok",
}

// On failure
{
  "status": "error",
  "error": "not_found",
}
```

#### `POST /:key/:fork/merge/:target`

Blindly merges the fork's data into the target. **This is a destructive
operation.** You are on your own for rollbacks.

**This *overwrites* the target fork with the provided fork!** This does NOT
do some sort of smart merge! The originating fork's value OVERWRITES the target
fork's value directly, and has the relevant patch added to its history.

```js
// On success
{
  "status": "ok",
}

// On failure
{
  "status": "error",
  "error": "fork_not_found",
}

{
  "status": "error",
  "error": "target_not_found",
}
```