defmodule JsonStruct do
  @moduledoc ~S"""
  `JsonStruct` is a module that provides a macro `__using__` that generates a struct with a set
  of fields and a set of functions to serialize and deserialize the struct to and from JSON in
  a type safe manner.

  ## Usage
  ```elixir
    defmodule Human do
      use JsonStruct,
        name: Types.Str,
        age: {Types.Int, &Human.check_age/1}
      
      def check_age(age) when age >= 0, do: true
      def check_age(_), do: false
    end

    {:ok, map} = Human.serialize(human)
    {:ok, human} = Human.deserialize(map | json)
  ```
  """

  defmacro __using__(fields) do
    quote do
      @fields unquote(fields)

      @enforce_keys Keyword.keys(@fields)

      defstruct Keyword.keys(@fields)

      @type t :: %__MODULE__{
              unquote_splicing(
                for {field, type_info} <- fields do
                  case type_info do
                    {type, _} -> {field, quote(do: unquote(type).t())}
                    type -> {field, quote(do: unquote(type).t())}
                  end
                end
              )
            }

      @spec serialize(__MODULE__.t()) :: Result.t(String.t(), String.t())
      def serialize(struct = %__MODULE__{}) do
        with {:ok, json} <- Poison.encode(struct),
             {:ok, struct} <- JsonStruct.Support.validate_and_build(struct, @fields, __MODULE__),
             do: {:ok, json}
      end

      @spec deserialize(String.t() | map()) :: Result.t(__MODULE__.t(), String.t())
      def deserialize(json) when is_binary(json) do
        with {:ok, map} <- JSON.decode(json),
             do: JsonStruct.Support.validate_and_build(map, @fields, __MODULE__)
      end

      def deserialize(%{} = map) do
        JsonStruct.Support.validate_and_build(map, @fields, __MODULE__)
      end
    end
  end
end

defmodule JsonStruct.Support do
  # Private module
  @moduledoc false

  def validate_and_build(map, fields, module) do
    result =
      Enum.reduce_while(fields, {:ok, %{}}, fn {field, type}, acc ->
        value = Map.get(map, field) || Map.get(map, Atom.to_string(field))

        if value do
          case validate_field(field, value, type) do
            {:ok, value} -> {:cont, {:ok, Map.put(elem(acc, 1), field, value)}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        else
          {:halt, {:error, "#{inspect(field)} is missing"}}
        end
      end)

    with {:ok, map} <- result,
         do: {:ok, struct(module, map)}
  end

  defp validate_field(field, value, {type, value_validator_fn}) do
    with {:ok, value} <- validate_field(field, value, type),
         do: validate_value(field, value, value_validator_fn)
  end

  defp validate_field(field, value, type) do
    case apply(type, :deserialize, [value]) do
      {:ok, value} ->
        {:ok, value}

      {:error, reason} ->
        {:error,
         "#{inspect(field)}(#{inspect(type)}) has incorrect type: #{inspect(value)}(#{inspect(reason)})"}
    end
  end

  defp validate_value(field, value, value_validator_fn) do
    if value_validator_fn.(value) do
      {:ok, value}
    else
      {:error, "#{inspect(field)} has incorrect value(#{inspect(value)})"}
    end
  end
end
