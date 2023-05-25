defmodule BetUnfair.MarketServer do
  use GenServer

  def start_link(name, description) do
    {:ok, market_db} = CubDB.start_link(data_dir: "./data/" <> name, auto_file_sync: true)
    CubDB.put_new(market_db, :description, description)
    CubDB.put_new(market_db, :status, :active)
    GenServer.start_link(__MODULE__, {name, market_db}, name: String.to_atom(name))
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:vivo, _from, state) do
    {:reply, :vivo, state}
  end

  @impl true
  def handle_call(
        {:bet_back, user_id, stake, odds, users_db, bets_db, bet_id},
        _from,
        state = {market_name, market_db}
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

        {:reply, {:ok, bet_id}, state}
      else
        CubDB.delete(market_name, {:back, odds, bet_id})
        {:reply, {:error, "Insufficient Money"}, state}
      end
    else
      {:reply, {:error, "Insufficient Money"}, state}
    end
  end

  @impl true
  def handle_call(
        {:bet_lay, user_id, stake, odds, users_db, bets_db, bet_id},
        _from,
        state = {market_name, market_db}
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

        {:reply, {:ok, bet_id}, state}
      else
        CubDB.delete(market_name, {:lay, odds, bet_id})
        {:reply, {:error, "Insufficient Money"}, state}
      end
    else
      {:reply, {:error, "Insufficient Money"}, state}
    end
  end

  @impl true
  def handle_call({:bet_get, bet_id}, _from, state = {_market_name, market_db}) do
    bet =
      CubDB.select(market_db)
      |> Enum.to_list()
      |> find_bet(bet_id)

    case bet do
      :error -> {:reply, :error, state}
      {^bet_id, bet_info} -> {:reply, {:ok, bet_info}, state}
    end
  end

  @impl true
  def handle_call(:market_match, _from, state = {_market_name, market_db}) do
    backs =
      CubDB.select(market_db, min_key: {:back, 0, nil}, max_key: {:back, nil, nil})
      |> Enum.to_list()

    lays =
      CubDB.select(market_db, reverse: true, min_key: {:lay, 0, nil}, max_key: {:lay, nil, nil})
      |> Enum.to_list()

    {new_backs, new_lays} = matching(backs, lays, market_db)

    Enum.each(new_backs, fn {key, value} -> CubDB.put(market_db, key, value) end)
    Enum.each(new_lays, fn {key, value} -> CubDB.put(market_db, key, value) end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:market_get, _from, state = {market_name, market_db}) do
    {:reply,
     {:ok,
      %{
        name: market_name,
        description: CubDB.get(market_db, :description),
        status: CubDB.get(market_db, :status)
      }}, state}
  end

  def handle_call({:market_cancel, users_db}, _from, state = {_market_name, market_db}) do
    CubDB.select(market_db, min_key: {:a, 0, 0})
    |> Enum.to_list()
    |> Enum.each(fn {bet_key, %{original_stake: stake, user_id: user_id}} ->
      CubDB.get_and_update(users_db, user_id, fn {user_name, user_balance, user_bets} ->
        {:ok, {user_name, user_balance + stake, user_bets}}
      end)

      CubDB.get_and_update(market_db, bet_key, fn bet_info ->
        {:ok, Map.put(bet_info, :status, :market_cancelled)}
      end)
    end)

    CubDB.put(market_db, :status, :cancelled)
    {:reply, :ok, state}
  end

  def handle_call({:market_freeze, users_db}, _from, state = {_market_name, market_db}) do
    CubDB.select(market_db, min_key: {:a, 0, 0})
    |> Enum.to_list()
    |> Enum.filter(fn {_, %{matched_bets: matched_bets}} ->
      matched_bets == []
    end)
    |> Enum.each(fn {bet_key, %{original_stake: stake, user_id: user_id}} ->
      CubDB.get_and_update(users_db, user_id, fn {user_name, user_balance, user_bets} ->
        {:ok, {user_name, user_balance + stake, user_bets}}
      end)

      CubDB.get_and_update(market_db, bet_key, fn bet_info ->
        {:ok, Map.put(bet_info, :status, :cancelled)}
      end)
    end)

    CubDB.put(market_db, :status, :frozen)
    {:reply, :ok, state}
  end

  defp matching(backs, lays, market_db) do
    case match_bets(backs, lays, market_db) do
      :error -> {backs, lays}
      {[], []} -> {[], []}
      {new_backs, new_lays} -> matching(new_backs, new_lays, market_db)
    end
  end

  defp match_bets([], [], _), do: {[], []}

  defp match_bets(
         [{{:back, back_odd, _}, _} | _],
         [{{:lay, lay_odd, _}, _} | _],
         _
       )
       when back_odd > lay_odd,
       do: :error

  defp match_bets(
         [{back_id = {:back, back_odd, back_bet_id}, back_info} | backs],
         [{lay_id = {:lay, lay_odd, lay_bet_id}, lay_info} | lays],
         market_db
       ) do
    back_stake = Map.get(back_info, :remaining_stake)
    lay_stake = Map.get(lay_info, :remaining_stake)

    if Kernel.trunc(back_stake * (back_odd / 100) - back_stake) >= lay_stake do
      # Consume lay_stake and apply new back_stake with formulae 1
      # Backing stake = backing_stake- (lay_stake / (lay_odds - 1))
      new_back_stake = Kernel.trunc(back_stake - lay_stake / ((lay_odd - 100) / 100))

      # Add to the field matched_bets the id of each other
      {_, new_back_info} =
        Map.put(back_info, :remaining_stake, new_back_stake)
        |> Map.get_and_update(:matched_bets, fn l -> {:ok, [lay_bet_id | l]} end)

      CubDB.get_and_update(market_db, lay_id, fn info ->
        Map.put(info, :remaining_stake, 0)
        |> Map.get_and_update(:matched_bets, fn l -> {:ok, [back_bet_id | l]} end)
      end)

      {[{back_id, new_back_info} | backs], lays}
    else
      # Consume back_stake and apply new lay_stake with formulae 2
      # Lay stake= lay_stake - (backing stake*odds - backing stake)
      new_lay_stake = Kernel.trunc(lay_stake - (back_stake * (back_odd / 100) - back_stake))

      # Add to the field matched_bets the id of each other
      {_, new_lay_info} =
        Map.put(lay_info, :remaining_stake, new_lay_stake)
        |> Map.get_and_update(:matched_bets, fn l -> {:ok, [back_bet_id | l]} end)

      CubDB.get_and_update(market_db, back_id, fn info ->
        Map.put(info, :remaining_stake, 0)
        |> Map.get_and_update(:matched_bets, fn l -> {:ok, [lay_bet_id | l]} end)
      end)

      {backs, [{lay_id, new_lay_info} | lays]}
    end
  end

  defp find_bet([head | list], bet_id) do
    case head do
      [] ->
        :error

      {{_, _, ^bet_id}, bet_info} ->
        {bet_id, bet_info}

      _ ->
        find_bet(list, bet_id)
    end
  end
end
