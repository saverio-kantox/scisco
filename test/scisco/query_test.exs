defmodule Scisco.QueryTest do
  use ExUnit.Case

  defmodule Repo do
    import Ecto.Query

    def all(q) do
      {query, params} =
        Ecto.Adapter.Queryable.plan_query(:all, Ecto.Adapters.Postgres, q |> select([r], r))

      {query
       |> Ecto.Adapters.Postgres.Connection.all()
       |> IO.iodata_to_binary(), params}
    end

    def one(_q), do: 42

    def query(queryable) do
      {query, _params} =
        Ecto.Adapter.Queryable.plan_query(:all, Ecto.Adapters.Postgres, queryable)

      query
    end
  end

  defmodule MyStruct do
    use Ecto.Schema

    schema "stuff" do
      field(:foo, :string)
      field(:bar, :integer)
    end
  end

  defmodule MyQuery do
    use Scisco.Query

    def repo(), do: Repo
    def base_queryable(), do: MyStruct |> where([u], u.foo != "baz")

    def filter(q, {:bar, 0}), do: q |> where([r], r.bar <= 0)
  end

  test "querying" do
    assert MyQuery.list(%{filter: %{"bar" => 1}}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') AND (s0."bar" = $1)},
              [1]}

    assert MyQuery.list(%{filter: %{"bar" => 0}}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') AND (s0."bar" <= 0)},
              []}

    assert MyQuery.list(%{filter: %{"foo" => "a"}}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') AND (s0."foo" = $1)},
              ["a"]}

    assert MyQuery.list(%{sort: "bar"}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') ORDER BY s0."bar"},
              []}

    assert MyQuery.list(%{sort: "-foo"}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') ORDER BY s0."foo" DESC},
              []}

    assert MyQuery.list(%{page: %{size: 5}}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') LIMIT $1 OFFSET $2},
              [5, 0]}

    assert MyQuery.list(%{page: %{size: 5, number: 2}}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') LIMIT $1 OFFSET $2},
              [5, 5]}

    assert MyQuery.list(%{page: %{limit: 5, offset: 7}}) ==
             {~s{SELECT s0."id", s0."foo", s0."bar" FROM "stuff" AS s0 WHERE (s0."foo" != 'baz') LIMIT $1 OFFSET $2},
              [5, 7]}
  end

  test "page count" do
    assert MyQuery.get_page_count(%{page: %{size: 5}}) == 9
    assert MyQuery.get_page_count(%{page: %{size: 5}}, allow_zero: true) == 9
  end
end
