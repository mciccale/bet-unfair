defmodule BetUnfair.Server do
  @moduledoc """
  A betting exchange system that allows users to place bets on different markets.
  """
  use GenServer

  # User types specification
  @type user_id :: String.t()
  @type user_info :: %{name: String.t(), id: user_id(), balance: integer()}

  # Market types specification
  @type market_id :: String.t()
  @type market_info :: %{
          name: String.t(),
          description: String.t(),
          status: :active | :frozen | :cancelled | {:settled, boolean()}
        }

  # Bet types specification
  @type bet_id :: integer()
  @type bet_odd :: {pos_integer(), bet_id()}
  @type bet_info :: %{
          odds: pos_integer(),
          bet_type: :back | :lay,
          market_id: market_id(),
          user_id: user_id(),
          original_stake: pos_integer(),
          remaining_stake: pos_integer(),
          matched_bets: [bet_id()],
          status:
            :active
            | :cancelled
            | :market_cancelled
            | {:market_settled, boolean()}
        }

  @type server_state :: %{server: atom(), db: atom()}

  # Exchange interaction
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

    # Recuperar ultimo id de bets

    bet_id = CubDB.select(bets_db) |> Enum.to_list() |> Enum.max(&>=/2, fn -> 0 end) #Trata el caso de que sea vacía la lista y devuelve 0

    GenServer.start_link(
      __MODULE__,
      {users_db, bets_db, markets, bet_id},
      name: :bet_unfair
    )
  end

  @spec stop() :: :ok
  def stop() do
    GenServer.call(:bet_unfair, :stop_db)
    GenServer.stop(:bet_unfair)
  end

  @spec clean(name :: String.t()) :: :ok
  def clean(_name) do
    case Process.whereis(:bet_unfair) do
      nil ->
        nil

      _ ->
        GenServer.call(:bet_unfair, :stop_db)
        GenServer.stop(:bet_unfair)
    end

    File.rm_rf("data")
    File.mkdir("data")
    :ok
  end

  # User interaction
  @spec user_create(id :: String.t(), name :: String.t()) :: {:ok, user_id()}
  def user_create(id, name) do
    GenServer.call(:bet_unfair, {:user_create, id, name})
  end

  @spec user_deposit(id :: user_id(), amount :: pos_integer()) :: :ok | :error
  def user_deposit(_id, amount) when amount < 1, do: :error

  def user_deposit(id, amount) do
    GenServer.call(:bet_unfair, {:user_deposit, id, amount})
  end

  @spec user_withdraw(id :: user_id(), amount :: pos_integer()) :: :ok | :error
  def user_withdraw(_id, amount) when amount < 1, do: :error

  def user_withdraw(id, amount) do
    GenServer.call(:bet_unfair, {:user_withdraw, id, amount})
  end

  @spec user_get(id :: user_id()) :: {:ok, user_info()} | :error
  def user_get(id) do
    GenServer.call(:bet_unfair, {:user_get, id})
  end

  @spec user_bets(id :: user_id()) :: Enum.t(bet_id()) | :error
  def user_bets(id) do
    GenServer.call(:bet_unfair, {:user_bets, id})
  end

  # Market interaction
  @spec market_create(name :: String.t(), description :: String.t()) ::
          {:ok, market_id()} | :error
  def market_create(name, description) do
    GenServer.call(:bet_unfair, {:market_create, name, description})
  end

  def market_alive(name) do
    pid = GenServer.call(:bet_unfair, {:market_alive, name})
    GenServer.call(pid, :vivo)
  end

  @spec market_list() :: {:ok, [market_id()]} | :error
  def market_list() do
    GenServer.call(:bet_unfair, :market_list)
  end

  @spec market_list_active() :: {:ok, [market_id()]} | :error
  def market_list_active() do
    GenServer.call(:bet_unfair, :market_list_active)
  end

  @spec market_cancel(id :: market_id()) :: :ok | :error
  def market_cancel(id) do
    {:ok, market_pid, users_db} = GenServer.call(:bet_unfair, {:market_cancel, id})
    GenServer.call(market_pid, {:market_cancel, users_db})
  end

  @spec market_freeze(id :: market_id()) :: :ok | :error
  def market_freeze(id) do
    {:ok, market_pid, users_db} = GenServer.call(:bet_unfair, {:market_freeze, id})
    GenServer.call(market_pid, {:market_freeze, users_db})
  end

  @spec market_settle(id :: market_id(), result :: boolean()) :: :ok | :error
  def market_settle(id, result) do
    case GenServer.call(:bet_unfair, {:market_settle, id, result}) do
      :error ->
        :error

      {:ok, market_pid, users_db} ->
        GenServer.call(market_pid, {:market_settle, result, users_db})
    end
  end

  @spec market_bets(id :: market_id()) :: {:ok, Enum.t(bet_id())} | :error
  def market_bets(id) do
    {:ok, market_pid} = GenServer.call(:bet_unfair, {:market_bets, id})
    GenServer.call(market_pid, :market_bets)
  end

  @spec market_pending_backs(id :: market_id()) :: {:ok, Enum.t(bet_odd())} | :error
  def market_pending_backs(id) do
    {:ok, market_pid} = GenServer.call(:bet_unfair, {:market_pending, id})
    GenServer.call(market_pid, :market_pending_backs)
  end

  @spec market_pending_lays(id :: market_id()) :: {:ok, Enum.t(bet_odd())} | :error
  def market_pending_lays(id) do
    {:ok, market_pid} = GenServer.call(:bet_unfair, {:market_pending, id})
    GenServer.call(market_pid, :market_pending_lays)
  end

  @spec market_get(id :: market_id()) :: {:ok, market_info()} | :error
  def market_get(id) do
    {:ok, market_pid} = GenServer.call(:bet_unfair, {:market_get, id})
    GenServer.call(market_pid, :market_get)
  end

  @spec market_match(id :: market_id()) :: :ok | :error
  def market_match(id) do
    GenServer.call(:bet_unfair, {:market_match, id})
  end

  # Bet interaction
  @spec bet_back(
          user_id :: user_id(),
          market_id :: market_id(),
          stake :: pos_integer(),
          odds :: pos_integer()
        ) :: {:ok, bet_id()} | :error

  def bet_back(user_id, market_id, stake, odds) do
    case GenServer.call(:bet_unfair, {:bet, market_id}) do
      :error ->
        :error

      {:ok, market_pid, user_db, bets_db, bet_id} ->
        GenServer.call(market_pid, {:bet_back, user_id, stake, odds, user_db, bets_db, bet_id})
    end
  end

  @spec bet_lay(
          user_id :: user_id(),
          market_id :: market_id(),
          stake :: pos_integer(),
          odds :: pos_integer()
        ) :: {:ok, bet_id()} | :error

  def bet_lay(user_id, market_id, stake, odds) do
    case GenServer.call(:bet_unfair, {:bet, market_id}) do
      :error ->
        :error

      {:ok, market_pid, user_db, bets_db, bet_id} ->
        GenServer.call(market_pid, {:bet_lay, user_id, stake, odds, user_db, bets_db, bet_id})
    end
  end

  @spec bet_cancel(id :: bet_id()) :: :ok | :error
  def bet_cancel(id) do
    {:ok, market_pid, users_db} = GenServer.call(:bet_unfair, {:bet_cancel, id})
    GenServer.call(market_pid, {:bet_cancel, id, users_db})
  end

  @spec bet_get(id :: bet_id()) :: {:ok, bet_info()} | :error
  def bet_get(id) do
    {:ok, market_pid} = GenServer.call(:bet_unfair, {:bet_get, id})
    GenServer.call(market_pid, {:bet_get, id})
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
    |> Enum.each(fn {_, {market_pid,_}} ->
      case Process.alive?(market_pid) do
        false -> nil
        true ->
          GenServer.call(market_pid, :stop_db)
          GenServer.stop(market_pid)
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
    with {:ok, market_pid} <- BetUnfair.MarketServer.start_link(name, description),
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
        {:market_alive, market_id},
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

  defp start_markets([], markets) do
    markets
  end

  defp start_markets([name | files], markets) do
    {:ok, market_db} = CubDB.start_link(data_dir: "./data/markets/" <> name, auto_file_sync: true)
    description = CubDB.get(market_db, :description)
    :ok = CubDB.stop(market_db)
    {:ok, market_pid} = BetUnfair.MarketServer.start_link(name, description)

    new_markets =
      Map.put(
        markets,
        name,
        {market_pid, %Structs.MarketInfo{name: name, description: description, status: :active}}
      )

    start_markets(files, new_markets)
  end
end
