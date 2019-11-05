defmodule Scisco.Utils do
  @doc """
  Convert key/value pairs into atom/value pairs
  """
  @spec k2a({String.t() | atom(), any()}) :: {atom(), any()}
  def k2a({k, v}), do: {to_atom?(k), v}

  @doc """
  Normalize params into a map fulfilling the `Scisco.Query.params()` type.
  """
  @spec normalize_params(nil | Enumerable.t()) :: nil | Scisco.Query.params()
  def normalize_params(nil), do: nil

  def normalize_params(params) do
    params = Map.new(params, &k2a/1) |> Map.take(~w[page filter sort]a)

    with %{page: page} when not is_nil(page) <- params do
      %{
        params
        | page:
            page
            |> Map.new(fn {k, v} -> {to_atom?(k), to_int?(v)} end)
            |> Map.take(~w[number size offset limit]a)
      }
    end
  end

  @doc """
  Convert strings to atoms, keeps atoms.
  """
  @spec to_atom?(String.t() | atom()) :: atom()
  def to_atom?(k) when is_atom(k), do: k
  def to_atom?(k) when is_binary(k), do: String.to_existing_atom(k)

  @doc """
  Convert strings to integers, keeps integers.
  """
  @spec to_int?(String.t() | integer()) :: integer()
  def to_int?(v) when is_integer(v), do: v
  def to_int?(v) when is_binary(v), do: String.to_integer(v)
end
