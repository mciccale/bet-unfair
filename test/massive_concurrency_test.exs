defmodule BetUnfair.MassiveConcurrencyTest do
  use ExUnit.Case

  test "client" do
    assert {:ok, c1} = BetUnfair.user_create("client1", "Francisco Gonzalez")
    assert :ok = BetUnfair.user_deposit(c1, 2000)

    Enum.map(1..1_000, fn _ ->
      spawn(fn -> BetUnfair.bet_back(c1, "ramiro no entra a telefónica", 2, 150) end)
    end)

    Process.sleep(100)

    assert {:ok, bets} = BetUnfair.market_bets("ramiro no entra a telefónica")
    assert 1_000 = Enum.to_list(bets) |> length()
  end
end
