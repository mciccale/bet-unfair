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
    {:ok, pid} =
      CubDB.start_link(
        data_dir: "./data/" <> name,
        auto_file_sync: true
      )

    GenServer.start_link(
      __MODULE__,
      %Structs.State{db: pid},
      name: :bet_unfair
    )
  end

  @spec stop() :: :ok | {:error, :db_not_started | :server_not_started}
  def stop() do
    case GenServer.call(:bet_unfair, :stop_db) do
      {:error, :not_started} -> {:error, :db_not_started}
      :ok -> :ok
    end

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
  def user_deposit(id, amount) do
    if amount < 1 do
      :error
    else
      GenServer.call(:bet_unfair, {:user_deposit, id, amount})
    end
  end

  @spec user_withdraw(id :: user_id(), amount :: pos_integer()) :: :ok | :error
  def user_withdraw(id, amount) do
    if amount < 1 do
      :error
    else
      GenServer.call(:bet_unfair, {:user_withdraw, id, amount})
    end
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
    pid =GenServer.call(:bet_unfair, {:market_alive, name})
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
    GenServer.call(:bet_unfair, {:market_cancel, id})
  end

  @spec market_freeze(id :: market_id()) :: :ok | :error
  def market_freeze(id) do
    # TODO
    :ok
  end

  @spec market_settle(id :: market_id(), result :: boolean()) :: :ok | :error
  def market_settle(id, result) do
    # TODO
    :ok
  end

  @spec market_bets(id :: market_id()) :: {:ok, Enum.t(bet_id())} | :error
  def market_bets(id) do
    {:ok, [0]}
  end

  @spec market_pending_backs(id :: market_id()) :: {:ok, Enum.t(bet_odd())} | :error
  def market_pending_backs(id) do
    # TODO
    {:ok, [{150, 0}]}
  end

  @spec market_pending_lays(id :: market_id()) :: {:ok, Enum.t(bet_odd())} | :error
  def market_pending_lays(id) do
    # TODO
    {:ok, [{150, 0}]}
  end

  @spec market_get(id :: market_id()) :: {:ok, market_info()} | :error
  def market_get(id) do
    # TODO
    {:ok, %{name: "Market1", description: "Soccer Market", status: :active}}
  end

  @spec market_match(id :: market_id()) :: :ok | :error
  def market_match(id) do
    :ok
  end

  # Bet interaction
  @spec bet_back(
          user_id :: user_id(),
          market_id :: market_id(),
          stake :: pos_integer(),
          odds :: pos_integer()
        ) :: {:ok, bet_id()} | :error


  def bet_back(user_id, market_id, stake, odds) do
    {:ok, pid, user_db} = GenServer.call(:bet_unfair, {:bet_back, market_id})
    GenServer.call(pid, {:bet_back, user_id, stake, odds, user_db})
  end

  @spec bet_lay(
          user_id :: user_id(),
          market_id :: market_id(),
          stake :: pos_integer(),
          odds :: pos_integer()
        ) :: {:ok, bet_id()} | :error
  def bet_lay(id, market_id, stake, odds) do
    {:ok, pid} = GenServer.call(:bet_unfair, {:bet_lay, market_id})
    GenServer.call(pid, {:bet_lay, id, stake, odds})
  end

  @spec bet_cancel(id :: bet_id()) :: :ok | :error
  def bet_cancel(id) do
    # TODO
    :ok
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
  def handle_call(:stop_db, _from, state) do
    case Map.get(state, :db) do
      nil ->
        {:reply, {:error, :not_started}, state}

      pid ->
        CubDB.stop(pid)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:user_create, id, name}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.put_new(db, id, {name, 0, []}) do
      :ok -> {:reply, {:ok, id}, state}
      {:error, _} -> {:reply, {:error, :exists}, state}
    end
  end

  @impl true
  def handle_call({:user_deposit, id, amount}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.get_and_update(db, id, fn {name, balance, bets_list} ->
           {:ok, {name, balance + amount, bets_list}}
         end) do
      :ok -> {:reply, :ok, state}
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:user_withdraw, id, amount}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.get_and_update(db, id, fn {name, balance, bets_list} ->
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
  def handle_call({:user_get, user_id}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.get(db, user_id) do
      {name, balance, _bets_list} ->
        {:reply, {:ok, %Structs.UserInfo{name: name, id: user_id, balance: balance}}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:user_bets, id}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.get(db, id) do
      {_name, _balance, bets_list} ->
        {:reply, bets_list, state}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:market_create, name, description}, _from, state) do
    with {:ok, pid} <- BetUnfair.MarketServer.start_link(name, description),
         markets <- Map.get(state, :markets),
         new_state <-
           Map.put(
             state,
             :markets,
             Map.put(
               markets,
               name,
               {pid, %Structs.MarketInfo{name: name, description: description, status: :active}}
             )
           ) do
      {:reply, {:ok, name}, new_state}
    else
      _ -> {:reply, :error, state}
    end
  end
  def handle_call({:market_alive, name}, _from, state) do
    markets = Map.get(state, :markets)
    {pid, _} = Map.get(markets, name)
    {:reply, pid, state}
  end
  @impl true
  def handle_call(:market_list, _from, state) do
    markets = Map.get(state, :markets)
    {:reply, {:ok, Map.keys(markets)}, state}
  end

  @impl true
  def handle_call(:market_list_active, _from, state) do
    market_active_list =
      Map.get(state, :markets)
      |> Enum.map(fn {_key, {_pid, market_info}} -> market_info end)
      |> Enum.filter(fn market_info -> Map.get(market_info, :status) == :active end)
      |> Enum.map(fn market_info -> Map.get(market_info, :name) end)

    {:reply, {:ok, market_active_list}, state}
  end

  @impl true
  def handle_call({:market_cancel, id}, _from, state) do
    # TO-DO devolver el dinero
    with markets <- Map.get(state, :markets),
         market <- Map.get(markets, id),
         new_state <-
           Map.put(
             state,
             :markets,
             Map.put(
               markets,
               id,
               Map.put(market, :status, :cancelled)
             )
           ) do
      {:reply, :ok, new_state}
    else
      _ -> {:reply, :error, state}
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:bet_back, market_id}, _from, state) do
    markets = Map.get(state, :markets)
    user_db = Map.get(state, :db)
    {pid, _} = Map.get(markets, market_id)

    {:reply, {:ok, pid, user_db}, state}
  end

  @impl true
  def handle_call({:bet_lay, market_id}, _from, state) do
    markets = Map.get(state, :markets)
    {pid, _} = Map.get(markets, market_id)
    {:reply, {:ok, pid}, state}
  end

  def handle_call({:bet_get, id}, _from, state) do
    db = Map.get(state, :db)
    users = CubDB.select(db) |> Enum.to_list()

    {market_id, bet_id} =
      Enum.find_value(users, fn {user_id, {_name, _money, bets}} ->
        {market, bet} = Enum.find(bets, fn {market, bet} -> bet == id end)
        if bet == id do {market, bet} else {:error, :err} end
      end)
    if market_id == :error do
      {:reply, :error, state}
    else
      markets = Map.get(state, :markets)
      {market_server_pid, _} = Map.get(markets, market_id)
      {:reply, {:ok, market_server_pid}, state}
    end

  end
end
