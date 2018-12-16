defmodule CrudryTest do
  use ExUnit.Case
  doctest Crudry

  # Context for Repo.
  defmodule Repo do
    def insert(changeset) do
      {:ok, changeset}
    end

    def all(_module) do
      [1, 2, 3]
    end

    def get(module, _id) do
      struct(module)
    end

    def get!(module, _id) do
      struct(module)
      |> Map.put(:bang, true)
    end

    def update(changeset) do
      {:ok, changeset}
    end

    def delete(_) do
      :deleted
    end
  end

  # Context for a schema
  defmodule Test do
    defstruct x: "123", bang: false

    # Each changeset functions changes `attrs` in a different way so
    # we can verify which one was called.
    # TODO: This is not a clean way to do it, so change it

    def changeset(test, attrs) do
      Map.merge(test, attrs)
    end

    def create_changeset(test, %{x: x}) do
      attrs = %{x: x + 1}
      Map.merge(test, attrs)
    end

    def update_changeset(test, %{x: x}) do
      attrs = %{x: x + 2}
      Map.merge(test, attrs)
    end
  end

  # Mock for a context
  defmodule Context do
    alias CrudryTest.Repo

    Crudry.create_functions CrudryTest.Test
  end

  test "creates the CRUD functions" do
    assert Context.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert Context.list_tests() == [1, 2, 3]
    assert Context.get_test(1) == %Test{x: "123"}
    assert Context.get_test!(3) == %Test{x: "123", bang: true}
    assert Context.update_test(struct(Test), %{x: 3}) == {:ok, %Test{x: 3}}
    assert Context.update_test(3, %{x: 3}) == {:ok, %Test{x: 3}}
    assert Context.delete_test(struct(Test)) == :deleted
    assert Context.delete_test(2) == :deleted
  end

  test "allow defining of create changeset" do
    defmodule ContextCreate do
      alias CrudryTest.Repo

      Crudry.create_functions CrudryTest.Test, create: :create_changeset
    end

    assert ContextCreate.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextCreate.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
  end

  test "allow defining of update changeset" do
    defmodule ContextUpdate do
      alias CrudryTest.Repo

      Crudry.create_functions CrudryTest.Test, update: :update_changeset
    end

    assert ContextUpdate.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextUpdate.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "allow defining of both changeset functions" do
    defmodule ContextBoth do
      alias CrudryTest.Repo

      Crudry.create_functions CrudryTest.Test, create: :create_changeset, update: :update_changeset
    end

    assert ContextBoth.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextBoth.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "allow defining default changeset functions for context" do
    defmodule ContextDefault do
      alias CrudryTest.Repo

      use Crudry, create: :create_changeset, update: :update_changeset
      Crudry.create_functions CrudryTest.Test
    end

    assert ContextDefault.create_test(%{x: 2}) == {:ok, %Test{x: 3}}
    assert ContextDefault.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 4}}
  end

  test "choose which CRUD functions are to be generated" do
    defmodule ContextOnly do
      alias CrudryTest.Repo

      Crudry.create_functions CrudryTest.Test, only: [:create, :list]
    end

    assert ContextOnly.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert Context.list_tests() == [1, 2, 3]
    assert length(ContextOnly.__info__(:functions)) == 2

    defmodule ContextExcept do
      alias CrudryTest.Repo

      Crudry.create_functions CrudryTest.Test, except: [:get!, :list, :delete]
    end

    assert ContextExcept.create_test(%{x: 2}) == {:ok, %Test{x: 2}}
    assert ContextExcept.update_test(struct(Test), %{x: 2}) == {:ok, %Test{x: 2}}
    assert length(ContextExcept.__info__(:functions)) == 3
  end
end
