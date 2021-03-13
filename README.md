# crush

A time-traveling, replicated, eventually-consistent key-value store.

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

### `PUT /:key`

Sets the value at the given key. The request body is the value that is set.
Returns the value that was set.

### `DELETE /:key`

Deletes the key from the store. Returns the literal string `"ok"`.