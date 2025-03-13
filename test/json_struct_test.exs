defmodule JsonStructTest do
  use ExUnit.Case

  defmodule Human do
    use JsonStruct,
      name: Types.Str,
      age: {Types.Int, &Human.check_age/1}

    def check_age(age) when age >= 0, do: true
    def check_age(_), do: false
  end

  test "JsonStruct" do
    human = %Human{name: "Carl", age: 30}

    assert Human.serialize(human) == {:ok, Poison.encode!(human)}

    assert Poison.encode!(human) |> Human.deserialize() == {:ok, human}
  end

  test "Invalid type" do
    human = %Human{name: 42, age: 30}

    assert Human.serialize(human) ==
             {:error, ":name(Types.Str) has incorrect type: 42(\"Invalid string\")"}

    assert Poison.encode!(human) |> Human.deserialize() ==
             {:error, ":name(Types.Str) has incorrect type: 42(\"Invalid string\")"}
  end

  test "Invalid value" do
    human = %Human{name: "Carl", age: -23}

    assert Human.serialize(human) ==
             {:error, ":age has incorrect value(-23)"}

    assert Poison.encode!(human) |> Human.deserialize() ==
             {:error, ":age has incorrect value(-23)"}
  end
end
