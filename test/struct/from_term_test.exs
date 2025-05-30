defmodule Struct.FromTermTest do
  use ExUnit.Case, async: true
  doctest Struct.FromTerm

  defmodule Bar do
    use Struct, {
      [Struct.FromTerm],
      basic_type: :string
    }
  end

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
      bar: Bar
    }
  end

  defmodule Float do
    use Struct, {
      [Struct.FromTerm],
      float: :float
    }
  end

  defmodule Bool do
    use Struct, {
      [Struct.FromTerm],
      bool: :boolean
    }
  end

  defmodule Any do
    use Struct, {
      [Struct.FromTerm],
      any: :any
    }
  end

  defmodule ListOfList do
    use Struct, {
      [Struct.FromTerm],
      list_of_list: {:list, {:list, :integer}}
    }
  end

  defmodule NegInteger do
    use Struct, {
      [Struct.FromTerm],
      neg_integer: :neg_integer
    }
  end

  defmodule NonNegInteger do
    use Struct, {
      [Struct.FromTerm],
      non_neg_integer: :non_neg_integer
    }
  end

  defmodule PosInteger do
    use Struct, {
      [Struct.FromTerm],
      pos_integer: :pos_integer
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
        "Failed to parse field basic_type of Elixir.Struct.FromTermTest.Foo: Expected a string, got 123"
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
        "Failed to parse field optional_type of Elixir.Struct.FromTermTest.Foo: Expected an integer, got \"not a number\""
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
       "Failed to parse field float of Elixir.Struct.FromTermTest.Float: Expected a float, got \"str\""}

    assert expected == Float.from_term(map)
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
       "Failed to parse field bool of Elixir.Struct.FromTermTest.Bool: Expected a boolean, got \"str\""}

    assert expected == Bool.from_term(map)
  end

  test "Any type" do
    map = %{any: 42}
    assert {:ok, struct!(Any, map)} == Any.from_term(map)

    map = %{any: "Hey"}
    assert {:ok, struct!(Any, map)} == Any.from_term(map)

    map = %{any: [42, "Hey"]}
    assert {:ok, struct!(Any, map)} == Any.from_term(map)
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
       "Failed to parse field list_of_list of Elixir.Struct.FromTermTest.ListOfList: Expected a list, got \"str\""}

    assert expected == ListOfList.from_term(map)
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
       "Failed to parse field neg_integer of Elixir.Struct.FromTermTest.NegInteger: Expected a neg integer, got \"str\""}

    assert expected == NegInteger.from_term(map)

    map = %{
      neg_integer: 0
    }

    expected =
      {:error,
       "Failed to parse field neg_integer of Elixir.Struct.FromTermTest.NegInteger: Expected a neg integer, got 0"}

    assert expected == NegInteger.from_term(map)
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
       "Failed to parse field non_neg_integer of Elixir.Struct.FromTermTest.NonNegInteger: Expected a non neg integer, got \"str\""}

    assert expected == NonNegInteger.from_term(map)

    map = %{
      non_neg_integer: -5
    }

    expected =
      {:error,
       "Failed to parse field non_neg_integer of Elixir.Struct.FromTermTest.NonNegInteger: Expected a non neg integer, got -5"}

    assert expected == NonNegInteger.from_term(map)
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
       "Failed to parse field pos_integer of Elixir.Struct.FromTermTest.PosInteger: Expected a pos integer, got \"str\""}

    assert expected == PosInteger.from_term(map)

    map = %{
      pos_integer: 0
    }

    expected =
      {:error,
       "Failed to parse field pos_integer of Elixir.Struct.FromTermTest.PosInteger: Expected a pos integer, got 0"}

    assert expected == PosInteger.from_term(map)
  end
end
