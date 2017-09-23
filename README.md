# Maps

A simple wrapper around Google maps with some convenience methods. Not intended
to compete with / replace any of the other Google Maps wrappers for Elixir, only
intended to expose a few of Google maps capabilities as simply as possible for
internal use.

## Config

```elixir
config :maps, key: "whatever your key is with proper permissions set"
```

## Usage

See inline doc tests at `lib/maps.ex`.

## Installation

```elixir
def deps do
  [
    {:maps, git: "https://github.com/justicedemocrats/maps_ex.git"}
  ]
end
```
