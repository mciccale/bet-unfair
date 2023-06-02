defmodule BetUnfair.Server do
  @moduledoc """
  A betting exchange system that allows users to place bets on different markets.
  """
  use GenServer

  @spec start_link(name :: String.t()) :: {:ok, pid()} | {:error, {:already_started, pid()}}
  def start_link(name) do
    {:ok, users_db} =
      CubDB.start_link(
        data_dir: "./data/" <> name <> "_users",
        auto_file_sync: true
      )

    {:ok, bets_db} =
      CubDB.start_link(
        data_dir: "./data/" <> name <> "_bets",
        auto_file_sync: true
      )

    File.mkdir("./data/markets")
    {:ok, files} = File.ls("./data/markets")
    markets = start_markets(files, %{})

    # Retrieving the last bet_id
    # In case it is empty, returns 0
    bet_id = CubDB.select(bets_db) |> Enum.to_list() |> Enum.max(&>=/2, fn -> 0 end)

    GenServer.start_link(
      BetUnfair.Server,
      {users_db, bets_db, markets, bet_id},
      name: :bet_unfair
    )
  end

  # Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:stop_db, _from, state = {users_db, bets_db, markets, _bet_id}) do
    case Process.alive?(users_db) do
      false -> nil
      true -> CubDB.stop(users_db)
    end

    case Process.alive?(bets_db) do
      false -> nil
      true -> CubDB.stop(bets_db)
    end

    Enum.to_list(markets)
    |> Enum.each(fn {_, {market_pid, _}} ->
      case Process.alive?(market_pid) do
        false ->
          nil

        true ->
          GenServer.call(market_pid, :stop_db)
          DynamicSupervisor.terminate_child(:bet_unfair_dynamic_supervisor, market_pid)
      end
    end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(
        {:user_create, id, name},
        _from,
        state = {users_db, _bets_db, _markets, _bet_id}
      ) do
    case CubDB.put_new(users_db, id, {name, 0, []}) do
      :ok -> {:reply, {:ok, id}, state}
      {:error, _} -> {:reply, {:error, :exists}, state}
    end
  end

  @impl true
  def handle_call(
        {:user_deposit, id, amount},
        _from,
        state = {users_db, _bets_db, _markets, _bet_id}
      ) do
    case CubDB.get_and_update(users_db, id, fn {name, balance, bets_list} ->
           {:ok, {name, balance + amount, bets_list}}
         end) do
      :ok -> {:reply, :ok, state}
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(
        {:user_withdraw, id, amount},
        _from,
        state = {users_db, _bets_db, _markets, _bet_id}
      ) do
    case CubDB.get_and_update(users_db, id, fn {name, balance, bets_list} ->
           cond do
             balance >= amount -> {:ok, {name, balance - amount, bets_list}}
             true -> {:error, {name, balance, bets_list}}
           end
         end) do
      :ok -> {:reply, :ok, state}
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:user_get, user_id}, _from, state = {users_db, _bets_db, _markets, _bet_id}) do
    case CubDB.get(users_db, user_id) do
      {name, balance, _bets_list} ->
        {:reply, {:ok, %Structs.UserInfo{name: name, id: user_id, balance: balance}}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:user_bets, id}, _from, state = {users_db, _bets_db, _markets, _bet_id}) do
    case CubDB.get(users_db, id) do
      {_name, _balance, bets_list} ->
        {:reply, {:ok, bets_list}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(
        {:market_create, name, description},
        _from,
        state = {users_db, bets_db, markets, bet_id}
      ) do
    with {:ok, market_pid} <- BetUnfair.DynamicSupervisor.start_child(name, description),
         new_markets <-
           Map.put(
             markets,
             name,
             {market_pid,
              %Structs.MarketInfo{name: name, description: description, status: :active}}
           ) do
      {:reply, {:ok, name}, {users_db, bets_db, new_markets, bet_id}}
    else
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(
        {:market_alive?, market_id},
        _from,
        state = {_users_db, _bets_db, markets, _bet_id}
      ) do
    {market_pid, _market_info} = Map.get(markets, market_id)
    {:reply, market_pid, state}
  end

  @impl true
  def handle_call(:market_list, _from, state = {_users_db, _bets_db, markets, _bet_id}) do
    {:reply, {:ok, Map.keys(markets)}, state}
  end

  @impl true
  def handle_call(:market_list_active, _from, state = {_users_db, _bets_db, markets, _bet_id}) do
    market_active_list =
      markets
      |> Enum.map(fn {_market_name, {_market_pid, market_info}} -> market_info end)
      |> Enum.filter(fn market_info -> Map.get(market_info, :status) == :active end)
      |> Enum.map(fn market_info -> Map.get(market_info, :name) end)

    {:reply, {:ok, market_active_list}, state}
  end

  @impl true
  def handle_call(
        {:market_match, market_id},
        _from,
        state = {_users_db, _bets_db, markets, _bet_id}
      ) do
    {market_pid, _market_info} = Map.get(markets, market_id)
    {:reply, GenServer.call(market_pid, :market_match), state}
  end

  @impl true
  def handle_call(
        {:market_cancel, market_id},
        _from,
        state = {users_db, bets_db, markets, bet_id}
      ) do
    with {market_pid, market} <- Map.get(markets, market_id),
         :active <- Map.get(market, :status),
         new_markets <-
           Map.put(
             markets,
             market_id,
             {market_pid, Map.put(market, :status, :cancelled)}
           ) do
      {:reply, {:ok, market_pid, users_db}, {users_db, bets_db, new_markets, bet_id}}
    else
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(
        {:market_freeze, market_id},
        _from,
        state = {users_db, bets_db, markets, bet_id}
      ) do
    with {market_pid, market} <- Map.get(markets, market_id),
         :active <- Map.get(market, :status),
         new_markets <-
           Map.put(
             markets,
             market_id,
             {market_pid, Map.put(market, :status, :frozen)}
           ) do
      {:reply, {:ok, market_pid, users_db}, {users_db, bets_db, new_markets, bet_id}}
    else
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(
        {:market_settle, market_id, result},
        _from,
        state = {users_db, bets_db, markets, bet_id}
      ) do
    case Map.get(markets, market_id) do
      {market_pid, market} ->
        status = Map.get(market, :status)

        if status == :active || status == :frozen do
          {:reply, {:ok, market_pid, users_db},
           {users_db, bets_db,
            Map.put(
              markets,
              market_id,
              {market_pid, Map.put(market, :status, {:settled, result})}
            ), bet_id}}
        else
          {:reply, :error, state}
        end

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(
        {:market_bets, market_id},
        _from,
        state = {_users_db, _bets_db, markets, _bet_id}
      ) do
    {market_pid, _} = Map.get(markets, market_id)
    {:reply, {:ok, market_pid}, state}
  end

  @impl true
  def handle_call(
        {:market_pending, market_id},
        _from,
        state = {_users_db, _bets_db, markets, _bet_id}
      ) do
    {market_pid, _} = Map.get(markets, market_id)
    {:reply, {:ok, market_pid}, state}
  end

  @impl true
  def handle_call(
        {:market_get, market_id},
        _from,
        state = {_users_db, _bets_db, markets, _bet_id}
      ) do
    {market_pid, _market_info} = Map.get(markets, market_id)
    {:reply, {:ok, market_pid}, state}
  end

  @impl true
  def handle_call({:bet, market_id}, _from, state = {users_db, bets_db, markets, bet_id}) do
    {market_pid, market_info} = Map.get(markets, market_id)

    case Map.get(market_info, :status) do
      :active ->
        {:reply, {:ok, market_pid, users_db, bets_db, bet_id},
         {users_db, bets_db, markets, bet_id + 1}}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:bet_get, bet_id}, _from, state = {_users_db, bets_db, markets, _bet_id}) do
    market =
      CubDB.select(bets_db, min_key: bet_id, max_key: bet_id)
      |> Enum.to_list()
      |> Enum.map(fn {_id, {_user_id, market_name}} -> market_name end)

    case market do
      [market_name | []] ->
        {market_pid, _market_info} = Map.get(markets, market_name)
        {:reply, {:ok, market_pid}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:bet_cancel, bet_id}, _from, state = {users_db, bets_db, markets, _bet_id}) do
    market =
      CubDB.select(bets_db, min_key: bet_id, max_key: bet_id)
      |> Enum.to_list()
      |> Enum.map(fn {_id, {_user_id, market_name}} -> market_name end)

    case market do
      [market_name | []] ->
        {market_pid, _market_info} = Map.get(markets, market_name)
        {:reply, {:ok, market_pid, users_db}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  defp start_markets([], markets), do: markets

  defp start_markets([name | files], markets) do
    {:ok, market_db} = CubDB.start_link(data_dir: "./data/markets/" <> name, auto_file_sync: true)
    description = CubDB.get(market_db, :description)
    CubDB.stop(market_db)
    {:ok, market_pid} = BetUnfair.DynamicSupervisor.start_child(name, description)

    new_markets =
      Map.put(
        markets,
        name,
        {market_pid, %Structs.MarketInfo{name: name, description: description, status: :active}}
      )

    start_markets(files, new_markets)
  end
end
