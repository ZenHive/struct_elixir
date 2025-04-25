# Struct

<!-- Struct Module Doc Separator !-->
Library to easily create structs and auto implement behaviors for them.

# Examples:

```elixir
# Simple case
defmodule User do
  use Struct,
    id: :integer,
    name: :string
end
# Will generate the following code ->
defmodule User do
  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{
    id: integer(),
    name: String.t()
  }
end
```

```elixir
# Using the derive feature to implement behaviour automatically
defmodule Foo do
  use Struct, {
    [Struct.FromTerm], # Will implement the behaviour `Struct.FromTerm` automatically
    field: :integer,
  }

  # from_term/1 is generated automatically
end
```

```elixir
# You can put other modules as types
defmodule Group do
  use Struct,
    id: :integer,
    name: :string,
    owner: User # Make sure not to add `.t()`
end
```

```elixir
# List and optional fields must be given like this to support derives
defmodule Group do
  use Struct,
    id: :integer,
    name: {:option, :string},
    owner: User, # Make sure not to add `.t()`
    users: {:list, User} # Make sure not to add `.t()`
end
```

```elixir
# You can print the generated code by adding the :debug flag
defmodule DebugExamples do
  use Struct, {
    :debug, # Put `:debug` here
    [], # With `:debug`, the derive list must be present even if it is empty
    id: :integer,
    name: {:option, :string},
  }
end
```

# Supported types:

- `:integer`
- `:string`
- `:boolean`
- `:float`
- `{:list, AnySupportedType}`
- `{:option, AnySupportedType}`
- `Module`

# Included Behaviours:

- `Struct.FromTerm`

# How to implement your own behaviours:

See `Struct.DeriveModuleBehaviour`

# Installation

```elixir
def deps do
  [
    {:struct, git: "https://github.com/ZenHive/struct_elixir.git", tag: "v0.1.1"},
  ]
end
```

<!-- Struct Module Doc Separator !-->
