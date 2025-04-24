defmodule Struct.FromTermTest do
  use ExUnit.Case, async: true
  doctest Struct.FromTerm

  defmodule Bar do
    use Struct, {
      [Struct.FromTerm],
      [basic_type: Struct.Types.Str]
    }
  end

  defmodule Foo do
    use Struct, {
      :debug,
      [Struct.FromTerm],
      [
        basic_type: Struct.Types.Str,
        basic_type_custom_key: [
          type: Struct.Types.Str,
          "Struct.FromTerm": [keys: "basicTypeCustomKey"]
        ],
        optional_type: {:option, Struct.Types.Int},
        list_type: {:list, Struct.Types.Str},
        nested_type: {:option, {:list, Struct.Types.Str}},
        nested_type_custom_key: [
          type: {:option, {:list, Struct.Types.Str}},
          "Struct.FromTerm": [keys: "CompletelyCustomKey"]
        ],
        bar: Bar
      ]
    }
  end

  describe "from_term/1" do
    test "successfully creates struct with all fields" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => 123,
        :list_type => ["a", "b", "c"],
        :nested_type => ["x", "y", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %{basic_type: "bar value"}
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: ["a", "b", "c"],
        nested_type: ["x", "y", "z"],
        nested_type_custom_key: ["1", "2", "3"],
        bar: %Bar{basic_type: "bar value"}
      }

      assert {:ok, expected} == Foo.from_term(map)
    end

    test "handles nil optional fields" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => nil,
        :list_type => ["a", "b", "c"],
        :nested_type => nil,
        "CompletelyCustomKey" => nil,
        :bar => %{basic_type: "bar value"}
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: nil,
        list_type: ["a", "b", "c"],
        nested_type: nil,
        nested_type_custom_key: nil,
        bar: %Bar{basic_type: "bar value"}
      }

      assert {:ok, expected} == Foo.from_term(map)
    end

    test "handles missing optional fields" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :list_type => ["a", "b", "c"],
        :bar => %{basic_type: "bar value"}
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: nil,
        list_type: ["a", "b", "c"],
        nested_type: nil,
        nested_type_custom_key: nil,
        bar: %Bar{basic_type: "bar value"}
      }

      assert {:ok, expected} == Foo.from_term(map)
    end

    test "handles invalid basic type" do
      map = %{
        # Wrong type
        :basic_type => 123,
        "basicTypeCustomKey" => "custom hello",
        :optional_type => nil,
        :list_type => [],
        :nested_type => ["x", "y", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %Bar{basic_type: "bar value"}
      }

      expected = {
        :error,
        "Failed to parse field basic_type of Elixir.Struct.FromTermTest.Foo: Expected string, got 123"
      }

      assert expected == Foo.from_term(map)
    end

    test "handles invalid optional type" do
      map = %{
        :basic_type => "0",
        "basicTypeCustomKey" => "custom hello",
        # Wrong type
        :optional_type => "not a number",
        :list_type => [],
        :nested_type => ["x", "y", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %Bar{basic_type: "bar value"}
      }

      expected = {
        :error,
        "Failed to parse field optional_type of Elixir.Struct.FromTermTest.Foo: Expected integer, got \"not a number\""
      }

      assert expected == Foo.from_term(map)
    end

    test "handles invalid list type" do
      map = %{
        :basic_type => "0",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => nil,
        # Wrong type
        :list_type => 42,
        :nested_type => ["x", "y", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %Bar{basic_type: "bar value"}
      }

      expected = {
        :error,
        "Failed to parse field list_type of Elixir.Struct.FromTermTest.Foo: Expected a list, got 42"
      }

      assert expected == Foo.from_term(map)
    end

    test "handles invalid nested type" do
      map = %{
        :basic_type => "0",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => nil,
        :list_type => [],
        # Wrong type
        :nested_type => "not a list",
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %Bar{basic_type: "bar value"}
      }

      expected = {
        :error,
        "Failed to parse field nested_type of Elixir.Struct.FromTermTest.Foo: Expected a list, got \"not a list\""
      }

      assert expected == Foo.from_term(map)
    end

    test "handles invalid complex type" do
      map = %{
        :basic_type => "0",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => nil,
        :list_type => [],
        :nested_type => [],
        "CompletelyCustomKey" => ["1", "2", "3"],
        # Wrong type
        :bar => nil
      }

      expected = {
        :error,
        "Failed to parse field bar of Elixir.Struct.FromTermTest.Foo: Expected a map for Elixir.Struct.FromTermTest.Bar data, got nil"
      }

      assert expected == Foo.from_term(map)
    end

    test "handles non-map input" do
      map = "not a map"

      expected = {
        :error,
        "Expected a map for Elixir.Struct.FromTermTest.Foo data, got \"not a map\""
      }

      assert expected == Foo.from_term(map)

      map = 123
      expected = {:error, "Expected a map for Elixir.Struct.FromTermTest.Foo data, got 123"}
      assert expected == Foo.from_term(map)

      map = [1, 2, 3]

      expected = {
        :error,
        "Expected a map for Elixir.Struct.FromTermTest.Foo data, got [1, 2, 3]"
      }

      assert expected == Foo.from_term(map)
    end

    test "handles empty lists" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => 123,
        :list_type => [],
        :nested_type => [],
        "CompletelyCustomKey" => [],
        :bar => %{basic_type: "bar value"}
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: [],
        nested_type: [],
        nested_type_custom_key: [],
        bar: %Bar{basic_type: "bar value"}
      }

      assert {:ok, expected} == Foo.from_term(map)
    end

    test "handles nested types (optional, lists)" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => 123,
        :list_type => ["a", "b", "c"],
        :nested_type => ["x", "2", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %{basic_type: "bar value"}
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: ["a", "b", "c"],
        nested_type: ["x", "2", "z"],
        nested_type_custom_key: ["1", "2", "3"],
        bar: %Bar{basic_type: "bar value"}
      }

      assert {:ok, expected} == Foo.from_term(map)
    end
  end
end
