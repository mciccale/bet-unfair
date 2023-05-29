defmodule BetUnfair.Test do
  use ExUnit.Case

  test "clean_existing_db" do
    assert :ok = BetUnfair.clean("testdb")
  end

  test "db" do
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert :ok = BetUnfair.stop()
  end

  # Comprueba la persistencia de datos, en este caso de usuarios
  test "users" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert is_error(BetUnfair.user_create("u1", "Francisco Gonzalez"))
    assert :ok = BetUnfair.stop()
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert is_error(BetUnfair.user_create("u1", "Francisco Gonzalez"))
  end

  test "user_create" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert is_error(BetUnfair.user_create("u1", "Francisco Gonzalez"))
    assert :ok = BetUnfair.stop()
  end

  test "user_create_deposit_get" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert is_error(BetUnfair.user_create("u1", "Francisco Gonzalez"))
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_error(BetUnfair.user_deposit(u1, -1))
    assert is_error(BetUnfair.user_deposit(u1, 0))
    assert is_error(BetUnfair.user_deposit("u11", 0))

    assert {:ok, %{name: "Francisco Gonzalez", id: "u1", balance: 2000}} =
             BetUnfair.user_get(u1)
  end

  test "user_create_deposit_withdraw_get" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert is_error(BetUnfair.user_create("u1", "Francisco Gonzalez"))
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_error(BetUnfair.user_deposit(u1, -1))
    assert is_error(BetUnfair.user_deposit(u1, 0))
    assert is_error(BetUnfair.user_deposit("u11", 0))
    assert is_ok(BetUnfair.user_withdraw(u1, 1000))

    assert {:ok, %{name: "Francisco Gonzalez", id: "u1", balance: 1000}} =
             BetUnfair.user_get(u1)

    assert is_error(BetUnfair.user_get("u2"))
  end

  test "market_create1" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, "market1"} = BetUnfair.market_create("market1", "descripcion")
  end

  test "market_create2" do

    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, "market2"} = BetUnfair.market_create("market2", "")
    assert :vivo = BetUnfair.market_alive("market2")
    assert {:ok, "market3"} = BetUnfair.market_create("market3", "")
    assert {:ok, "market4"} = BetUnfair.market_create("market4", "")
    assert {:ok, ["market2", "market3", "market4"]} = BetUnfair.market_list()
    assert {:ok, ["market2", "market3", "market4"]} = BetUnfair.market_list_active()
  end

  test "user_bet1" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert is_ok(BetUnfair.user_deposit(u1, 3000))
    assert {:ok, %{balance: 3000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert :vivo = BetUnfair.market_alive(m1)
    assert {:ok, l} = BetUnfair.bet_lay(u1, m1, 1000, 150)

    assert {:ok,
          %{
               odds: 150,
               bet_type: :lay,
               market_id: m1,
               user_id: u1,
               original_stake: 1000,
               remaining_stake: 1000,
               matched_bets: [],
               status: :active
             }} = BetUnfair.bet_get(l)
    assert {:ok, b} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok,
        %{
               odds: 150,
               bet_type: :back,
               market_id: m1,
               user_id: u1,
               original_stake: 1000,
               remaining_stake: 1000,
               matched_bets: [],
               status: :active
             }} = BetUnfair.bet_get(b)


    assert {:ok, markets} = BetUnfair.market_list()
    assert 1 = length(markets)
    assert {:ok, markets} = BetUnfair.market_list_active()
    assert 1 = length(markets)
  end

  test "user_persist" do

    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, b} = BetUnfair.bet_back(u1, m1, 1000, 150)

    assert {:ok,
            %{
              odds: 150,
              bet_type: :back,
              market_id: m1,
              user_id: u1,
              original_stake: 1000,
              remaining_stake: 1000,
              matched_bets: [],
              status: :active
            }} = BetUnfair.bet_get(b)

    assert is_ok(BetUnfair.stop())
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, %{name: "Francisco Gonzalez", id: "u1", balance: 1000}} = BetUnfair.user_get(u1)
    assert {:ok, markets} = BetUnfair.market_list()
    assert 1 = length(markets)
    assert {:ok, markets} = BetUnfair.market_list_active()
    assert 1 = length(markets)
  end

  test "match_bets1" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, bl1} = BetUnfair.bet_lay(u2, m1, 500, 140)
    assert {:ok, bl2} = BetUnfair.bet_lay(u2, m1, 500, 150)
    assert {:ok, %{balance: 1000}} = BetUnfair.user_get(u2)
    # assert {:ok, backs} = BetUnfair.market_pending_backs(m1)
    # assert [^bb1, ^bb2] = Enum.to_list(backs) |> Enum.map(fn e -> elem(e, 1) end)
    # assert {:ok, lays} = BetUnfair.market_pending_lays(m1)
    # assert [^bl2, ^bl1] = Enum.to_list(lays) |> Enum.map(fn e -> elem(e, 1) end)
    assert is_ok(BetUnfair.market_match(m1))

    assert {:ok,
            %{
              odds: 150,
              bet_type: :back,
              market_id: m1,
              user_id: u1,
              original_stake: 1000,
              remaining_stake: 0,
              matched_bets: [bl2],
              status: :active
            }} = BetUnfair.bet_get(bb1)

    assert {:ok,
            %{
              odds: 150,
              bet_type: :lay,
              market_id: m1,
              user_id: u2,
              original_stake: 500,
              remaining_stake: 0,
              matched_bets: [bb1],
              status: :active
            }} = BetUnfair.bet_get(bl2)
  end

  test "match_bets2" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 1000, 140)
    assert {:ok, bl2} = BetUnfair.bet_lay(u2, m1, 1000, 150)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert {:ok, %{remaining_stake: 0}} = BetUnfair.bet_get(bb1)
    assert {:ok, %{remaining_stake: 500}} = BetUnfair.bet_get(bl2)
  end

  test "match_bets3" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert {:ok, %{remaining_stake: 800}} = BetUnfair.bet_get(bb1)
    assert {:ok, %{remaining_stake: 0}} = BetUnfair.bet_get(bl2)
    assert {:ok, user_bets} = BetUnfair.user_bets(u1)
    assert 2 = length(user_bets)
  end

  test "match_bets4" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_cancel(m1))
    assert :error = BetUnfair.bet_back(u2, m1, 100, 140)
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u2)
  end

  test "freeze1" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_freeze(m1))
    assert :error = BetUnfair.bet_back(u2, m1, 100, 140)
    assert :error = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u2)
  end

  test "match_bets5" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_settle(m1, true))
    assert {:ok, %{balance: 2100}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 1900}} = BetUnfair.user_get(u2)
  end

  test "match_bets6" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_settle(m1, false))
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2200}} = BetUnfair.user_get(u2)
  end

  test "match_bets7" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_freeze(m1))
    assert is_error(BetUnfair.bet_lay(u2, m1, 100, 150))
    assert is_ok(BetUnfair.market_settle(m1, false))
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2200}} = BetUnfair.user_get(u2)
  end

  test "match_bets8" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 200, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 200, 153)
    assert {:ok, %{balance: 1600}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_settle(m1, true))
    assert {:ok, %{balance: 2100}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 1900}} = BetUnfair.user_get(u2)
  end

  test "match_bets9" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 200, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 200, 153)
    assert {:ok, %{balance: 1600}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_settle(m1, false))
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2200}} = BetUnfair.user_get(u2)
  end

  test "match_bets10" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 800, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 800, 153)
    assert {:ok, %{balance: 400}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_settle(m1, true))
    assert {:ok, %{balance: 2200}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
  end

  test "match_bets11" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 200, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 200, 150)
    assert {:ok, %{balance: 1600}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, _bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, _bl2} = BetUnfair.bet_lay(u2, m1, 800, 150)
    assert {:ok, %{balance: 1100}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.market_settle(m1, false))
    assert {:ok, %{balance: 1600}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2400}} = BetUnfair.user_get(u2)
  end

  test "bet_cancel1" do
    assert :ok = BetUnfair.clean("testdb")
    assert {:ok, _} = BetUnfair.start_link("testdb")
    assert {:ok, u1} = BetUnfair.user_create("u1", "Francisco Gonzalez")
    assert {:ok, u2} = BetUnfair.user_create("u2", "Maria Fernandez")
    assert is_ok(BetUnfair.user_deposit(u1, 2000))
    assert is_ok(BetUnfair.user_deposit(u2, 2000))
    assert {:ok, %{balance: 2000}} = BetUnfair.user_get(u1)
    assert {:ok, m1} = BetUnfair.market_create("rmw", "Real Madrid wins")
    assert {:ok, bb1} = BetUnfair.bet_back(u1, m1, 1000, 150)
    assert {:ok, bb2} = BetUnfair.bet_back(u1, m1, 1000, 153)
    assert {:ok, %{balance: 0}} = BetUnfair.user_get(u1)
    assert true = bb1 != bb2
    assert {:ok, bl1} = BetUnfair.bet_lay(u2, m1, 100, 140)
    assert {:ok, bl2} = BetUnfair.bet_lay(u2, m1, 100, 150)
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_match(m1))
    assert is_ok(BetUnfair.bet_cancel(bl1))
    assert is_ok(BetUnfair.bet_cancel(bb2))
    assert {:ok, %{balance: 1000}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 1900}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.bet_cancel(bl2))
    assert is_ok(BetUnfair.bet_cancel(bb1))
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 1900}} = BetUnfair.user_get(u2)
    assert is_ok(BetUnfair.market_settle(m1, false))
    assert {:ok, %{balance: 1800}} = BetUnfair.user_get(u1)
    assert {:ok, %{balance: 2200}} = BetUnfair.user_get(u2)
  end

  defp is_error(:error), do: true
  defp is_error({:error, _}), do: true
  defp is_error(_), do: false

  defp is_ok(:ok), do: true
  defp is_ok({:ok, _}), do: true
  defp is_ok(_), do: false
end
