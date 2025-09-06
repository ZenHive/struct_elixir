defmodule Struct.FromTermTest do
  use ExUnit.Case, async: true
  doctest Struct.FromTerm

  defmodule Bar do
    use Struct, {
      [Struct.FromTerm],
      basic_type: :string
    }
  end

  describe "from_term/1" do
    defmodule Foo do
      use Struct, {
        :debug,
        [Struct.FromTerm],
        basic_type: :string,
        basic_type_custom_key: [
          type: :string,
          "Struct.FromTerm": [keys: "basicTypeCustomKey"]
        ],
        optional_type: {:option, :integer},
        list_type: {:list, :string},
        nested_type: {:option, {:list, :string}},
        nested_type_custom_key: [
          type: {:option, {:list, :string}},
          "Struct.FromTerm": [keys: "CompletelyCustomKey"]
        ],
        bar: Bar,
        one_of_type: {:one_of, [:string, :integer, Bar]}
      }
    end

    test "successfully creates struct with all fields" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => 123,
        :list_type => ["a", "b", "c"],
        :nested_type => ["x", "y", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: ["a", "b", "c"],
        nested_type: ["x", "y", "z"],
        nested_type_custom_key: ["1", "2", "3"],
        bar: %Bar{basic_type: "bar value"},
        one_of_type: 42
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
        :bar => %{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: nil,
        list_type: ["a", "b", "c"],
        nested_type: nil,
        nested_type_custom_key: nil,
        bar: %Bar{basic_type: "bar value"},
        one_of_type: 42
      }

      assert {:ok, expected} == Foo.from_term(map)
    end

    test "handles missing optional fields" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :list_type => ["a", "b", "c"],
        :bar => %{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: nil,
        list_type: ["a", "b", "c"],
        nested_type: nil,
        nested_type_custom_key: nil,
        bar: %Bar{basic_type: "bar value"},
        one_of_type: 42
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
        :bar => %Bar{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = {
        :error,
        "Failed to parse field basic_type of Elixir.Struct.FromTermTest.Foo: Expected a string, got: 123"
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
        :bar => %Bar{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = {
        :error,
        "Failed to parse field optional_type of Elixir.Struct.FromTermTest.Foo: Expected an integer, got: \"not a number\""
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
        :bar => %Bar{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = {
        :error,
        "Failed to parse field list_type of Elixir.Struct.FromTermTest.Foo: Expected a list, got: 42"
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
        :bar => %Bar{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = {
        :error,
        "Failed to parse field nested_type of Elixir.Struct.FromTermTest.Foo: Expected a list, got: \"not a list\""
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
        :bar => nil,
        :one_of_type => 42
      }

      expected = {
        :error,
        "Failed to parse field bar of Elixir.Struct.FromTermTest.Foo: Expected a map for Elixir.Struct.FromTermTest.Bar data, got: nil"
      }

      assert expected == Foo.from_term(map)
    end

    test "handles non-map input" do
      map = "not a map"

      expected = {
        :error,
        "Expected a map for Elixir.Struct.FromTermTest.Foo data, got: \"not a map\""
      }

      assert expected == Foo.from_term(map)

      map = 123
      expected = {:error, "Expected a map for Elixir.Struct.FromTermTest.Foo data, got: 123"}
      assert expected == Foo.from_term(map)

      map = [1, 2, 3]

      expected = {
        :error,
        "Expected a map for Elixir.Struct.FromTermTest.Foo data, got: [1, 2, 3]"
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
        :bar => %{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: [],
        nested_type: [],
        nested_type_custom_key: [],
        bar: %Bar{basic_type: "bar value"},
        one_of_type: 42
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
        :bar => %{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: ["a", "b", "c"],
        nested_type: ["x", "2", "z"],
        nested_type_custom_key: ["1", "2", "3"],
        bar: %Bar{basic_type: "bar value"},
        one_of_type: 42
      }

      assert {:ok, expected} == Foo.from_term(map)
    end

    test "one_of type" do
      map = %{
        :basic_type => "hello",
        "basicTypeCustomKey" => "custom hello",
        :optional_type => 123,
        :list_type => ["a", "b", "c"],
        :nested_type => ["x", "y", "z"],
        "CompletelyCustomKey" => ["1", "2", "3"],
        :bar => %{basic_type: "bar value"},
        :one_of_type => 42
      }

      expected = %Foo{
        basic_type: "hello",
        basic_type_custom_key: "custom hello",
        optional_type: 123,
        list_type: ["a", "b", "c"],
        nested_type: ["x", "y", "z"],
        nested_type_custom_key: ["1", "2", "3"],
        bar: %Bar{basic_type: "bar value"},
        one_of_type: 42
      }

      assert {:ok, expected} == Foo.from_term(map)

      map = %{map | :one_of_type => "a string"}
      expected = %Foo{expected | :one_of_type => "a string"}
      assert {:ok, expected} == Foo.from_term(map)

      map = %{map | :one_of_type => %{basic_type: "valid value"}}
      expected = %Foo{expected | :one_of_type => %Bar{basic_type: "valid value"}}
      assert {:ok, expected} == Foo.from_term(map)

      map = %{map | :one_of_type => %{basic_type: :invalid_value}}

      assert {:error,
              "Failed to parse field one_of_type of Elixir.Struct.FromTermTest.Foo: Expected " <>
                "one of `String.t() | integer() | Bar.t()`, got: %{basic_type: :invalid_value}"} ==
               Foo.from_term(map)

      map = %{map | :one_of_type => :yo}

      assert {:error,
              "Failed to parse field one_of_type of Elixir.Struct.FromTermTest.Foo: Expected " <>
                "one of `String.t() | integer() | Bar.t()`, got: :yo"} ==
               Foo.from_term(map)
    end
  end

  describe "float" do
    defmodule Float do
      use Struct, {
        [Struct.FromTerm],
        float: :float
      }
    end

    test "Valid float" do
      map = %{
        float: 0.5
      }

      expected = %Float{float: 0.5}

      assert {:ok, expected} == Float.from_term(map)
    end

    test "Invalid float" do
      map = %{
        float: "str"
      }

      expected =
        {:error,
         "Failed to parse field float of Elixir.Struct.FromTermTest.Float: Expected a float, got: \"str\""}

      assert expected == Float.from_term(map)
    end
  end

  describe "boolean" do
    defmodule Bool do
      use Struct, {
        [Struct.FromTerm],
        bool: :boolean
      }
    end

    test "Valid bool" do
      map = %{
        bool: true
      }

      expected = %Bool{bool: true}

      assert {:ok, expected} == Bool.from_term(map)
    end

    test "Invalid bool" do
      map = %{
        bool: "str"
      }

      expected =
        {:error,
         "Failed to parse field bool of Elixir.Struct.FromTermTest.Bool: Expected a boolean, got: \"str\""}

      assert expected == Bool.from_term(map)
    end
  end

  describe "any" do
    defmodule Any do
      use Struct, {
        [Struct.FromTerm],
        any: :any
      }
    end

    test "Any type" do
      map = %{any: 42}
      assert {:ok, struct!(Any, map)} == Any.from_term(map)

      map = %{any: "Hey"}
      assert {:ok, struct!(Any, map)} == Any.from_term(map)

      map = %{any: [42, "Hey"]}
      assert {:ok, struct!(Any, map)} == Any.from_term(map)
    end
  end

  describe "list of lists" do
    defmodule ListOfList do
      use Struct, {
        [Struct.FromTerm],
        list_of_list: {:list, {:list, :integer}}
      }
    end

    test "Valid list of list" do
      map = %{
        list_of_list: [[42, 43], [45, 46, 48]]
      }

      expected = %ListOfList{list_of_list: [[42, 43], [45, 46, 48]]}

      assert {:ok, expected} == ListOfList.from_term(map)
    end

    test "Invalid list of list" do
      map = %{
        list_of_list: "str"
      }

      expected =
        {:error,
         "Failed to parse field list_of_list of Elixir.Struct.FromTermTest.ListOfList: Expected a list, got: \"str\""}

      assert expected == ListOfList.from_term(map)
    end
  end

  describe "neg_integer" do
    defmodule NegInteger do
      use Struct, {
        [Struct.FromTerm],
        neg_integer: :neg_integer
      }
    end

    test "Valid neg_integer" do
      map = %{
        neg_integer: -5
      }

      expected = %NegInteger{neg_integer: -5}
      assert {:ok, expected} == NegInteger.from_term(map)
    end

    test "Invalid neg_integer" do
      map = %{
        neg_integer: "str"
      }

      expected =
        {:error,
         "Failed to parse field neg_integer of Elixir.Struct.FromTermTest.NegInteger: Expected a neg integer, got: \"str\""}

      assert expected == NegInteger.from_term(map)

      map = %{
        neg_integer: 0
      }

      expected =
        {:error,
         "Failed to parse field neg_integer of Elixir.Struct.FromTermTest.NegInteger: Expected a neg integer, got: 0"}

      assert expected == NegInteger.from_term(map)
    end
  end

  describe "non_neg_integer" do
    defmodule NonNegInteger do
      use Struct, {
        [Struct.FromTerm],
        non_neg_integer: :non_neg_integer
      }
    end

    test "Valid non_neg_integer" do
      map = %{
        non_neg_integer: 0
      }

      expected = %NonNegInteger{non_neg_integer: 0}
      assert {:ok, expected} == NonNegInteger.from_term(map)
    end

    test "Invalid non_neg_integer" do
      map = %{
        non_neg_integer: "str"
      }

      expected =
        {:error,
         "Failed to parse field non_neg_integer of Elixir.Struct.FromTermTest.NonNegInteger: Expected a non neg integer, got: \"str\""}

      assert expected == NonNegInteger.from_term(map)

      map = %{
        non_neg_integer: -5
      }

      expected =
        {:error,
         "Failed to parse field non_neg_integer of Elixir.Struct.FromTermTest.NonNegInteger: Expected a non neg integer, got: -5"}

      assert expected == NonNegInteger.from_term(map)
    end
  end

  describe "pos_integer" do
    defmodule PosInteger do
      use Struct, {
        [Struct.FromTerm],
        pos_integer: :pos_integer
      }
    end

    test "Valid pos_integer" do
      map = %{
        pos_integer: 1
      }

      expected = %PosInteger{pos_integer: 1}
      assert {:ok, expected} == PosInteger.from_term(map)
    end

    test "Invalid pos_integer" do
      map = %{
        pos_integer: "str"
      }

      expected =
        {:error,
         "Failed to parse field pos_integer of Elixir.Struct.FromTermTest.PosInteger: Expected a pos integer, got: \"str\""}

      assert expected == PosInteger.from_term(map)

      map = %{
        pos_integer: 0
      }

      expected =
        {:error,
         "Failed to parse field pos_integer of Elixir.Struct.FromTermTest.PosInteger: Expected a pos integer, got: 0"}

      assert expected == PosInteger.from_term(map)
    end
  end

  describe "generic atom" do
    defmodule GenericAtom do
      use Struct, {
        [Struct.FromTerm],
        atom: :atom
      }
    end

    test "Valid generic atom" do
      map = %{atom: :hello}
      expected = %GenericAtom{atom: :hello}
      assert {:ok, expected} == GenericAtom.from_term(map)

      # String not supported for generic atoms to avoid possible memory leaks
      map = %{atom: "world"}

      expected =
        {:error,
         "Failed to parse field atom of Elixir.Struct.FromTermTest.GenericAtom: Expected an atom, got: \"world\""}

      assert expected == GenericAtom.from_term(map)
    end

    test "Invalid generic atom" do
      map = %{atom: 123}

      expected =
        {:error,
         "Failed to parse field atom of Elixir.Struct.FromTermTest.GenericAtom: Expected an atom, got: 123"}

      assert expected == GenericAtom.from_term(map)
    end
  end

  describe "specific atom" do
    defmodule SpecificAtom do
      use Struct, {
        [Struct.FromTerm],
        atom: {:atom, :Hey}
      }
    end

    test "Valid specific atom" do
      map = %{atom: :Hey}
      expected = %SpecificAtom{atom: :Hey}
      assert {:ok, expected} == SpecificAtom.from_term(map)

      map = %{atom: "Hey"}
      expected = %SpecificAtom{atom: :Hey}
      assert {:ok, expected} == SpecificAtom.from_term(map)
    end

    test "Invalid specific atom" do
      map = %{atom: :Nope}

      expected =
        {:error,
         "Failed to parse field atom of Elixir.Struct.FromTermTest.SpecificAtom: Expected the atom Hey, got: :Nope"}

      assert expected == SpecificAtom.from_term(map)

      map = %{atom: "Nope"}

      expected =
        {:error,
         "Failed to parse field atom of Elixir.Struct.FromTermTest.SpecificAtom: Expected the atom Hey, got: \"Nope\""}

      assert expected == SpecificAtom.from_term(map)
    end
  end

  describe "tuple" do
    defmodule Tuple do
      use Struct, {
        :debug,
        [Struct.FromTerm],
        tuple: {:tuple, [:integer, Bar, :string]}
      }
    end

    test "Valid tuple" do
      # With tuple as tuple
      map = %{tuple: {42, %{basic_type: "bar value"}, "hello"}}
      expected = %Tuple{tuple: {42, %Bar{basic_type: "bar value"}, "hello"}}
      assert {:ok, expected} == Tuple.from_term(map)

      # With tuple as list
      map = %{tuple: [42, %{basic_type: "bar value"}, "hello"]}
      expected = %Tuple{tuple: {42, %Bar{basic_type: "bar value"}, "hello"}}
      assert {:ok, expected} == Tuple.from_term(map)
    end

    test "Invalid tuple" do
      map = %{tuple: "not a tuple"}

      expected =
        {:error,
         "Failed to parse field tuple of Elixir.Struct.FromTermTest.Tuple: Expected {integer(), Bar.t(), String.t()}, got: \"not a tuple\""}

      assert expected == Tuple.from_term(map)
      map = %{tuple: {42, nil, "hello"}}

      expected =
        {:error,
         "Failed to parse field tuple of Elixir.Struct.FromTermTest.Tuple: Expected {integer(), Bar.t(), String.t()}, got: {42, nil, \"hello\"}"}

      assert expected == Tuple.from_term(map)
      map = %{tuple: {42, %{basic_type: "bar value"}}}

      expected =
        {:error,
         "Failed to parse field tuple of Elixir.Struct.FromTermTest.Tuple: Expected {integer(), Bar.t(), String.t()}, got: {42, %{basic_type: \"bar value\"}}"}

      assert expected == Tuple.from_term(map)
    end
  end
end
