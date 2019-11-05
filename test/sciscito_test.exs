defmodule SciscoTest do
  use ExUnit.Case

  defp assert_normalize_passthru(thing) do
    assert Scisco.Utils.normalize_params(thing) == thing
  end

  test "parameter normalization" do
    assert_normalize_passthru(nil)
    assert_normalize_passthru(%{})
    assert_normalize_passthru(%{page: %{number: 2}})
    assert_normalize_passthru(%{page: %{size: 2}})
    assert_normalize_passthru(%{sort: "asdg", filter: %{}, page: %{size: 2}})
  end
end
