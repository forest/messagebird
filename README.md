<!-- MDOC !-->

A [Messagebird](https://developers.messagebird.com) Client, built on top of [Finch](https://github.com/keathley/finch).

## Usage

In order to use Messagebird, you must start it and provide a `:name`. Often in your supervision tree:

```elixir
children = [
  {Messagebird, name: MyMessagebirdClient}
]
```

Or, in rare cases, dynamically:

```elixir
Messagebird.start_link(name: MyMessagebirdClient)
```

Or, with the your own module:

```elixir
defmodule MyMessagebirdClient do
  use Messagebird
end

children = [
  MyMessagebirdClient
]
```

Once you have started your instance of Messagebird, you are ready to start sending SMS messages:

```elixir
config = [base_url: "https://rest.messagebird.com", access_key: "test_access_key"]

MyMessagebirdClient.send_text_message(config, "+18002345678", "Test message", originator: "TEST")
```

<!-- MDOC !-->

## Installation

The package can be installed by adding `messagebird` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:messagebird, "~> 0.1"}
  ]
end
```
