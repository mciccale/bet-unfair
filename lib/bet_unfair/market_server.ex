defmodule BetUnfair.MarketServer do
  use GenServer

  def start_link(name, description) do
    {:ok, market_db} = CubDB.start_link(data_dir: "./data/" <> name, auto_file_sync: true)
    CubDB.put_new(market_db, :description, description)
    GenServer.start_link(__MODULE__, {name, market_db}, name: String.to_atom(name))
  end

  @impl true
  def init({market_name, market_db}) do
    {:ok, {market_name, market_db}}
  end

  def handle_call(:vivo, _from, state) do
    {:reply, :vivo, state}
  end

  @impl true
  def handle_call(
        {:bet_back, user_id, stake, odds, users_db, bets_db, bet_id},
        _from,
        {market_name, market_db}
      ) do
    {_name, money, _bets} = CubDB.get(users_db, user_id)

    if money >= stake do
      CubDB.put_new(
        market_db,
        {:back, odds, bet_id},
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

      {user_name, money, bets} = CubDB.get(users_db, user_id)

      if money >= stake do
        CubDB.put(
          users_db,
          user_id,
          {user_name, money - stake, [bet_id | bets]}
        )

        CubDB.put(
          bets_db,
          bet_id,
          {user_id, market_name}
        )

        {:reply, {:ok, bet_id}, {market_name, market_db}}
      else
        CubDB.delete(market_name, {:back, odds, bet_id})
        {:reply, {:error, "Insufficient Money"}, {market_name, market_db}}
      end
    else
      {:reply, {:error, "Insufficient Money"}, {market_name, market_db}}
    end
  end

  @impl true
  def handle_call(
        {:bet_lay, user_id, stake, odds, users_db, bets_db, bet_id},
        _from,
        {market_name, market_db}
      ) do
    {_name, money, _bets} = CubDB.get(users_db, user_id)

    if money >= stake do
      CubDB.put_new(
        market_db,
        {:lay, odds, bet_id},
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

      {user_name, money, bets} = CubDB.get(users_db, user_id)

      if money >= stake do
        CubDB.put(
          users_db,
          user_id,
          {user_name, money - stake, [bet_id | bets]}
        )

        CubDB.put(
          bets_db,
          bet_id,
          {user_id, market_name}
        )

        {:reply, {:ok, bet_id}, {market_name, market_db}}
      else
        CubDB.delete(market_name, {:lay, odds, bet_id})
        {:reply, {:error, "Insufficient Money"}, {market_name, market_db}}
      end
    else
      {:reply, {:error, "Insufficient Money"}, {market_name, market_db}}
    end
  end

  def handle_call({:bet_get, bet_id}, _from, {market_name, market_db}) do
    algo = CubDB.select(market_db) |> Enum.to_list() |> find_bet(bet_id)
    case algo do
      :error -> {:reply, :error, {market_name, market_db}}
      {^bet_id, bet_info} -> {:reply, {:ok, {bet_id, bet_info}}, {market_name, market_db}}
    end
  end

  defp find_bet([head | list], bet_id) do
    case head do
      [] -> :error
      {{_, _, ^bet_id}, bet_info} -> {bet_id, bet_info}
      _ ->
        find_bet(list, bet_id)
    end
  end

  def handle_call(:market_match, _from, {market_name, market_db}) do
    backs =
      CubDB.select(market_db, min_key: {:back, 0, nil})
      |> Enum.to_list()

    lays =
      CubDB.select(market_db, reverse: true, min_key: {:lay, 0, nil})
      |> Enum.to_list()

    {new_backs, new_lays} = matching(backs, lays)
    Enum.each(new_backs, fn {key, value} -> CubDB.put(market_db, key, value) end)
    Enum.each(new_lays, fn {key, value} -> CubDB.put(market_db, key, value) end)
    {:reply, :ok, {market_name, market_db}}
  end

  defp matching(backs, lays) do
    case match_bets(backs, lays) do
      :error -> {backs, lays}
      {[], []} -> {[], []}
      {new_backs, new_lays} -> matching(new_backs, new_lays)
    end
  end

  defp match_bets([], []), do: {[], []}

  defp match_bets(
         [{{:back, back_odd, _}, _} | _],
         [{{:lay, lay_odd, _}, _} | _]
       )
       when back_odd > lay_odd,
       do: :error

  defp match_bets([{{:back, back_odd, back_id}, back_info} | backs], [
         {{:lay, lay_odd, lay_id}, lay_info} | lays
       ]) do
    back_stake = Map.get(back_info, :remaining_stake)
    lay_stake = Map.get(lay_info, :remaining_stake)

    if back_stake * back_odd - back_stake >= lay_stake do
      # Consume lay_stake and apply new back_stake with formulae 1
      # Backing stake = backing_stake- (lay_stake / (lay_odds - 1))
      new_back_stake = Kernel.trunc(back_stake - lay_stake / ((lay_odd - 100) / 100))

      {[{{:back, back_odd, back_id}, Map.put(back_info, :remaining_stake, new_back_stake)}], lays}
    else
      # Consume back_stake and apply new lay_stake with formulae 2
      # Lay stake= lay_stake - (backing stake*odds - backing stake)
      new_lay_stake = lay_stake - (back_stake * back_odd - back_stake)

      {backs, [{{:lay, lay_odd, lay_id}, Map.put(lay_info, :remaining_stake, new_lay_stake)}]}
    end
  end
end
