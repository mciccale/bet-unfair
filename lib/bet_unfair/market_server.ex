defmodule BetUnfair.MarketServer do
  use GenServer

  def start_link(name, description) do
    {:ok, pid} = CubDB.start_link(data_dir: "./data/" <> name, auto_file_sync: true)
    CubDB.put_new(pid, :description, description)
    GenServer.start_link(__MODULE__, {name, pid, 0}, name: String.to_atom(name))
  end

  @impl true
  def init({name, pid, 0}) do
    {:ok, {name, pid, 0}}
  end

  @impl true
  def handle_call({:bet_back, id, stake, odds, user_db}, _from, {market_name, pid, bet_id}) do
    {name, money, bets} = CubDB.get(user_db, id)

    if money > stake do
      CubDB.put_new(
        market_name,
        {:back, odds, bet_id + 1},
        %{
          odds: odds,
          bet_type: :back,
          market_id: market_name,
          user_id: id,
          original_stake: stake,
          remaining_stake: stake,
          matched_bets: [],
          status: :active
        }
      )
      {user_name, money, bets} = CubDB.get(user_db, id)
      if money > stake do
        CubDB.put(user_db, id, {user_name, money - stake, [{market_name,bet_id + 1} | bets]})
        {:reply, {:ok, bet_id + 1}, {market_name, pid, bet_id + 1}}
      else
        CubDB.delete(market_name, {:back, odds, bet_id + 1})
        {:reply, {:error, "Insufficient Money"}, {name, pid, bet_id}}
      end
    else
      {:reply, {:error, "Insufficient Money"}, {name, pid, bet_id}}
    end
  end

  @impl true
  def handle_call({:bet_lay, id, stake, odds}, _from, {market_name, pid, new_id}) do
    CubDB.put_new(
      market_name,
      {:lay, odds, new_id + 1},
      %{
        odds: odds,
        bet_type: :lay,
        market_id: market_name,
        user_id: id,
        original_stake: stake,
        remaining_stake: stake,
        matched_bets: [],
        status: :active
      }
    )
    {:reply, {:ok, new_id + 1}, {market_name, pid, new_id + 1}}
  end
end
