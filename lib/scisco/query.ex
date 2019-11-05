defmodule Scisco.Query do
  @moduledoc """
  Easy pagination/sorting/filtering.

  Use this module to provide the default Scisco query interface:

  ```
  defmodule MyQuery do
    use Scisco.Query

    def base_queryable(), do: MySchema
    def repo(), do: MyRepo
  end
  ```

  and then call it from outside:

  ```
  MyQuery.list(%{page: %{number: 3, size: 10}, filter: %{"foo" => "bar"}, sort: "-baz"})
  ```

  ## Pagination

  The query module supports by default two pagination strategies: the "classic paginator" style
  (with `:size` and `:number` keys - `:number` defaulting to 1) and the "raw paginator" style
  (with `:limit` and `:offset` keys - `:offset` defaulting to 0).

  ## Sorting

  By default any string in the sort key will enforce sorting the queryable by the corresponding
  field of the queryable - descending if the string starts with `"-"`, ascending otherwise.

  One can implement additional clauses that respect the `sort_callback` typespec. The clauses
  will always receive `:asc` or `:desc` depending on whether the original sort param starts with `"-"`.

  ```
  defmodule MyQuery do
    use Scisco.Query

    def base_queryable(), do: MySchema
    def repo(), do: MyRepo

    def sort(queryable, {:some_key, :asc})
    def sort(queryable, {:some_key, :desc})
  end
  ```

  ## Filtering

  By default any key in the filter map will be converted into an exact match of the corresponding
  field of the queryable.

  One can implement additional clauses that respect the `filter_callback` typespec.

  ```
  defmodule MyQuery do
    use Scisco.Query

    def base_queryable(), do: MySchema
    def repo(), do: MyRepo

    def filter(queryable, {:some_key, value})
  end
  ```

  """

  @doc """
  Needs to be implemented by the module, returning an initial queryable for pagination etc.
  """
  @callback base_queryable() :: Ecto.Queryable.t()

  @doc """
  Needs to be implemented by the module, returning the Ecto Repo with which to actually
  execute the queries.
  """
  @callback repo() :: term()

  @doc """
  Implements specific sorting behavior. Falls back to sorting by the given field
  """
  @callback sort(queryable :: Ecto.Queryable.t(), {field :: atom(), direction :: :asc | :desc}) ::
              Ecto.Queryable.t()

  @doc """
  Implements specific filtering behavior. Falls back to match the term with the field
  """
  @callback filter(queryable :: Ecto.Queryable.t(), {field :: atom(), value :: term()}) ::
              Ecto.Queryable.t()

  @type page_param ::
          nil
          | %{:size => pos_integer(), optional(:number) => pos_integer()}
          | %{:limit => pos_integer(), optional(:offset) => non_neg_integer()}

  @type sort_param :: nil | String.t()
  @type filter_param :: nil | %{optional(String.t()) => term()}

  @type sort_callback :: (Ecto.Queryable.t(), {atom(), :asc | :desc} -> Ecto.Queryable.t())
  @type filter_callback :: (Ecto.Queryable.t(), {atom(), term()} -> Ecto.Queryable.t())

  @typedoc "The map representing the query params."
  @type params :: %{
          optional(:page) => page_param,
          optional(:sort) => sort_param,
          optional(:filter) => filter_param
        }

  import Ecto.Query, warn: false
  import Scisco.Utils, only: [k2a: 1]

  @doc false
  defmacro __using__(_opts \\ []) do
    quote generated: true do
      import Ecto.Query, warn: false

      @behaviour Scisco.Query
      @before_compile Scisco.Query

      @doc """
      Lists all the records, filtered and paginated according to the passed params.
      """
      @spec list(params :: Scisco.Query.params()) :: [Ecto.Schema.t()]
      def list(params) do
        base_queryable()
        |> Scisco.Query.filter(params[:filter], &filter/2)
        |> Scisco.Query.sort(params[:sort], &sort/2)
        |> Scisco.Query.paginate(params[:page])
        |> repo().all()
      end

      @doc """
      Returns the number of pages.

      Requires either `params[:page][:size]` or `params[:page][:limit]` to be a number.

      When no record is found, a count of 1 page is returned anyways, to ease the build of
      pagination interfaces - in the end a user is "seeing" page 1 even if it's empty.

      To override this behavior and return 0 pages, pass `allow_zero: true` in options.
      """
      @spec get_page_count(params :: Scisco.Query.params(), opts :: [{:allow_zero, boolean}]) ::
              non_neg_integer()
      def get_page_count(params, opts \\ []) do
        page_count =
          base_queryable()
          |> Scisco.Query.filter(params[:filter], &filter/2)
          |> select([u], count(u.id, :distinct))
          |> repo().one()
          |> Kernel.-(1)
          |> Integer.floor_div(get_in(params, ~w[page size]a) || get_in(params, ~w[page limit]a))
          |> Kernel.+(1)

        if Keyword.get(opts, :allow_zero, false) || page_count > 0, do: page_count, else: 1
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def sort(queryable, {key, direction}) do
        from(u in queryable, order_by: ^[{direction, key}])
      end

      def filter(queryable, {key, value}) do
        from(u in queryable, where: ^[{key, value}])
      end
    end
  end

  @doc "Performs an actual pagination."
  @spec paginate(queryable :: any(), params :: nil | page_param()) :: any()
  def paginate(queryable, nil), do: queryable

  def paginate(queryable, %{size: page_size} = param) do
    page_number = Map.get(param, :number, 1)
    from(u in queryable, limit: ^page_size, offset: ^((page_number - 1) * page_size))
  end

  def paginate(queryable, %{limit: page_limit} = param) do
    page_offset = Map.get(param, :offset, 0)
    from(u in queryable, limit: ^page_limit, offset: ^page_offset)
  end

  @doc "Performs an actual sorting."
  @spec sort(queryable :: Ecto.Queryable.t(), params :: sort_param, cb :: sort_callback) ::
          Ecto.Queryable.t()
  def sort(queryable, nil, _), do: queryable
  def sort(queryable, "", _), do: queryable
  def sort(queryable, "-" <> key, cb), do: cb.(queryable, k2a({key, :desc}))
  def sort(queryable, key, cb), do: cb.(queryable, k2a({key, :asc}))

  @doc "Performs an actual filtering."
  @spec filter(queryable :: Ecto.Queryable.t(), params :: filter_param, cb :: filter_callback) ::
          Ecto.Queryable.t()
  def filter(queryable, nil, _), do: queryable

  def filter(queryable, %{} = filters, cb) do
    for {k, v} <- filters, reduce: queryable do
      queryable -> cb.(queryable, k2a({k, v}))
    end
  end
end
