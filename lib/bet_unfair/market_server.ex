defmodule BetUnfair.MarketServer do
  use GenServer

  def start_link(name, description) do
    {:ok, db_pid} = CubDB.start_link(data_dir: "./data/" <> name, auto_file_sync: true)
    CubDB.put_new(db_pid, :description, description)
    GenServer.start_link(__MODULE__, {name, db_pid, 0}, name: String.to_atom(name))
  end

  @impl true
  def init({name, pid, 0}) do
    {:ok, {name, pid, 0}}
  end

  def handle_call(:vivo, _from, state) do
    {:reply, :vivo, state}
  end

  @impl true
  def handle_call({:bet_back, user_id, stake, odds, user_db}, _from, {market_name, db_pid, bet_id}) do
    {_name, money, _bets} = CubDB.get(user_db, user_id)

    if money >= stake do
      CubDB.put_new(
        db_pid,
        {:back, odds, bet_id + 1},
        %{
          odds: odds,
          bet_type: :back,
          market_id: market_name,
          user_id: user_id,
          original_stake: stake,
          remaining_stake: stake,
          matched_bets: [],
          status: :active
        }
      )

      {user_name, money, bets} = CubDB.get(user_db, user_id)

      if money >= stake do
        CubDB.put(user_db, user_id, {user_name, money - stake, [{market_name, bet_id + 1} | bets]})
        {:reply, {:ok, bet_id + 1}, {market_name, db_pid, bet_id + 1}}
      else
        CubDB.delete(market_name, {:back, odds, bet_id + 1})
        {:reply, {:error, "Insufficient Money"}, {market_name, db_pid, bet_id}}
      end
    else
      {:reply, {:error, "Insufficient Money"}, {market_name, db_pid, bet_id}}
    end
  end

  @impl true
  def handle_call({:bet_lay, user_id, stake, odds, user_db}, _from, {market_name, db_pid, bet_id}) do
    {_name, money, _bets} = CubDB.get(user_db, user_id)

    if money >= stake do
      CubDB.put_new(
        db_pid,
        {:lay, odds, bet_id + 1},
        %{
          odds: odds,
          bet_type: :lay,
          market_id: market_name,
          user_id: user_id,
          original_stake: stake,
          remaining_stake: stake,
          matched_bets: [],
          status: :active
        }
      )

      {user_name, money, bets} = CubDB.get(user_db, user_id)

      if money >= stake do
        CubDB.put(user_db, user_id, {user_name, money - stake, [{market_name, bet_id + 1} | bets]})
        {:reply, {:ok, bet_id + 1}, {market_name, db_pid, bet_id + 1}}
      else
        CubDB.delete(market_name, {:lay, odds, bet_id + 1})
        {:reply, {:error, "Insufficient Money"}, {market_name, db_pid, bet_id}}
      end
    else
      {:reply, {:error, "Insufficient Money"}, {market_name, db_pid, bet_id}}
    end
  end

  def handle_call({:bet_get, bet_id}, _from, {market_name, db_pid, actual_id}) do
    {_, bet_info} =
      CubDB.select(db_pid, min_key: {:a, 0, bet_id})
      |> Enum.to_list()
      |> Enum.find(fn {{_, _, id}, _} -> bet_id == id end)

    {:reply, {:ok, bet_info}, {market_name, db_pid, actual_id}}
  end
end
