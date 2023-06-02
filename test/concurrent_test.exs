defmodule BetUnfair.ConcurrentTest do
  use ExUnit.Case

  defmodule Client1 do
    use ExUnit.Case, async: true

    test "connection" do
      assert {:ok, c1} = BetUnfair.user_create("client1", "Francisco Gonzalez")
      assert :ok = BetUnfair.user_deposit(c1, 2000)

      assert {:ok, %{name: "Francisco Gonzalez", id: "client1", balance: 2000}} =
               BetUnfair.user_get(c1)

      assert {:ok, l} = BetUnfair.bet_lay(c1, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :lay,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c1,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(l)

      assert {:ok, b} = BetUnfair.bet_back(c1, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :back,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c1,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(b)
    end
  end

  defmodule Client2 do
    use ExUnit.Case, async: true

    test "connection" do
      assert {:ok, c2} = BetUnfair.user_create("client2", "Segismundo García")
      assert :ok = BetUnfair.user_deposit(c2, 2000)

      assert {:ok, %{name: "Segismundo García", id: "client2", balance: 2000}} =
               BetUnfair.user_get(c2)

      assert {:ok, l} = BetUnfair.bet_lay(c2, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :lay,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c2,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(l)

      assert {:ok, b} = BetUnfair.bet_back(c2, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :back,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c2,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(b)
    end
  end

  defmodule Client3 do
    use ExUnit.Case, async: true

    test "connection" do
      assert {:ok, c3} = BetUnfair.user_create("client3", "Eustaquio Pradera")
      assert :ok = BetUnfair.user_deposit(c3, 2000)

      assert {:ok, %{name: "Eustaquio Pradera", id: "client3", balance: 2000}} =
               BetUnfair.user_get(c3)

      assert {:ok, l} = BetUnfair.bet_lay(c3, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :lay,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c3,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(l)

      assert {:ok, b} = BetUnfair.bet_back(c3, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :back,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c3,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(b)
    end
  end

  defmodule Client4 do
    use ExUnit.Case, async: true

    test "connection" do
      assert {:ok, c4} = BetUnfair.user_create("client4", "Devorah Guisado")
      assert :ok = BetUnfair.user_deposit(c4, 2000)

      assert {:ok, %{name: "Devorah Guisado", id: "client4", balance: 2000}} =
               BetUnfair.user_get(c4)

      assert {:ok, l} = BetUnfair.bet_lay(c4, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :lay,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c4,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(l)

      assert {:ok, b} = BetUnfair.bet_back(c4, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :back,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c4,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(b)
    end
  end

  defmodule Client5 do
    use ExUnit.Case, async: true

    test "connection" do
      assert {:ok, c5} = BetUnfair.user_create("client5", "Armando Guerra")
      assert :ok = BetUnfair.user_deposit(c5, 2000)

      assert {:ok, %{name: "Armando Guerra", id: "client5", balance: 2000}} =
               BetUnfair.user_get(c5)

      assert {:ok, l} = BetUnfair.bet_lay(c5, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :lay,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c5,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(l)

      assert {:ok, b} = BetUnfair.bet_back(c5, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :back,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c5,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(b)
    end
  end

  defmodule Client6 do
    use ExUnit.Case, async: true

    test "connection" do
      assert {:ok, c6} = BetUnfair.user_create("client6", "Pat el Cartero")
      assert :ok = BetUnfair.user_deposit(c6, 2000)

      assert {:ok, %{name: "Pat el Cartero", id: "client6", balance: 2000}} =
               BetUnfair.user_get(c6)

      assert {:ok, l} = BetUnfair.bet_lay(c6, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :lay,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c6,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(l)

      assert {:ok, b} = BetUnfair.bet_back(c6, "ramiro no entra a telefónica", 1000, 150)

      assert {:ok,
              %{
                odds: 150,
                bet_type: :back,
                market_id: "ramiro no entra a telefónica",
                user_id: ^c6,
                original_stake: 1000,
                remaining_stake: 1000,
                matched_bets: [],
                status: :active
              }} = BetUnfair.bet_get(b)
    end
  end
end
