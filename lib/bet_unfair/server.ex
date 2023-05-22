defmodule BetUnfair.Server do
  use GenServer

  @moduledoc """
  A betting exchange system that allows users to place bets on different markets.
  """

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
    # Start the DB
    CubDB.start_link(data_dir: "./data/" <> name, name: String.to_atom(name))
    # Start the server
    GenServer.start_link(
      BetUnfair.Server,
      %{db: String.to_atom(name), markets: %{}},
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
  def clean(name) do
    # Check if DB is running
    case Process.whereis(String.to_atom(name)) do
      nil ->
        :ok

      _ ->
        # Stop the DB
        CubDB.stop(String.to_atom(name))
    end

    # Delete the DB (in case it exists)
    path = "./data/" <> name
    File.rm_rf(path)
    # Check if server is running
    case Process.whereis(:bet_unfair) do
      nil ->
        :ok

      _ ->
        # Stop the server
        GenServer.stop(:bet_unfair)
    end
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
    GenServer.call(:bet_unfair, {:user_bet, id})
  end

  # Market interaction
  @spec market_create(name :: String.t(), description :: String.t()) ::
          {:ok, market_id()} | :error
  def market_create(name, description) do
    GenServer.call(:bet_unfair, {:market_create, name, description})
  end

  @spec market_list() :: {:ok, [market_id()]} | :error
  def market_list() do
    GenServer.call(:bet_unfair, {:market_list})
  end

  @spec market_list_active() :: {:ok, [market_id()]} | :error
  def market_list_active() do
    # TODO
    {:ok, ["Market1"]}
  end

  @spec market_cancel(id :: market_id()) :: :ok | :error
  def market_cancel(id) do
    # TODO
    :ok
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
  def bet_back(id, market_id, stake, odds) do
    # TODO
    {:ok, 0}
  end

  @spec bet_lay(
          user_id :: user_id(),
          market_id :: market_id(),
          stake :: pos_integer(),
          odds :: pos_integer()
        ) :: {:ok, bet_id()} | :error
  def bet_lay(id, market_id, stake, odds) do
    # TODO
    {:ok, 0}
  end

  @spec bet_cancel(id :: bet_id()) :: :ok | :error
  def bet_cancel(id) do
    # TODO
    :ok
  end

  @spec bet_get(id :: bet_id()) :: {:ok, bet_info()} | :error
  def bet_get(id) do
    # TODO
    {:ok,
     %{
       bet_type: :back,
       market_id: "Market1",
       user_id: "DNI-1234",
       odds: 150,
       original_stake: 2000,
       remaining_stake: 1500,
       matched_bets: [0, 1, 2],
       status: :active
     }}
  end

  # GenServer Functions
  @spec init(%{server: atom(), db: atom()}) :: {:ok, %{server: atom(), db: atom()}}
  def init(state) do
    {:ok, state}
  end

  def handle_call(:stop_db, _from, state) do
    case Map.get(state, :db) do
      nil ->
        {:reply, {:error, :not_started}, state}

      name ->
        path = "./data/" <> Atom.to_string(name)
        # Create backup
        File.mkdir("./swap")
        CubDB.back_up(name, "./swap/" <> Atom.to_string(name))
        # Delete previous directory if exists
        File.rm_rf(path)
        # Move backup to data directory
        File.mkdir(path)
        File.copy("./swap/" <> Atom.to_string(name) <> "/0.cub", path <> "/0.cub")
        # Delete swap directory
        File.rm_rf("./swap/" <> Atom.to_string(name))
        # Stop the DB
        CubDB.stop(name)
        {:reply, :ok, state}
    end
  end

  def handle_call({:user_create, id, name}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.put_new(db, id, {name, 0, []}) do
      :ok -> {:reply, {:ok, id}, state}
      {:error, _} -> {:reply, {:error, :exists}, state}
    end
  end

  def handle_call({:user_deposit, id, amount}, _from, state) do
    db = Map.get(state, :db)

    case CubDB.get_and_update(db, id, fn {name, curBalance, bet_list} ->
           {:ok, {name, curBalance + amount, bet_list}}
         end) do
      :ok -> {:reply, :ok, state}
      _ -> {:reply, :error, state}
    end
  end

  def handle_call({:user_withdraw, id, amount}, _from, state) do
    db = Map.get(state, :db)
    user = CubDB.get(db, id)

    case user do
      {name, balance, bet_list} when balance >= amount ->
        {:reply, CubDB.put(db, id, {name, balance - amount, bet_list}), state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:user_get, id}, _from, state) do
    db = Map.get(state, :db)
    user = CubDB.get(db, id)

    case user do
      {name, balance, _} ->
        {:reply, {:ok, %{name: name, id: id, balance: balance}}, state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:user_bet, id}, _from, state) do
    db = Map.get(state, :db)
    user = CubDB.get(db, id)

    case user do
      {_, _, bet_list} ->
        {:reply, bet_list, state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:market_create, name, description}, _from, state) do
    with {:ok, pid} <- BetUnfair.MarketServer.start_link(name, description),
         db <- Map.get(state, :db),
         :ok <- CubDB.put_new(db, String.to_atom(name), pid) do
      {:reply, {:ok, name}, state}
    else
      _ -> {:reply, :error, state}
    end
  end

  def handle_call({:market_list}, _from, state) do
    db = Map.get(state, :db)
  end

  # Private functions
  def insert_ordered([], bet), do: [bet]

  def insert_ordered(
        [{bet_id, user_id, odd, stake} | rest],
        {new_bet_id, new_user_id, new_odd, new_stake}
      )
      when new_odd < odd do
    [{new_bet_id, new_user_id, new_odd, new_stake} | [{bet_id, user_id, odd, stake} | rest]]
  end

  def insert_ordered(
        [{bet_id, user_id, odd, stake} | rest],
        {new_bet_id, new_user_id, new_odd, new_stake}
      ) do
    [
      {bet_id, user_id, odd, stake}
      | insert_ordered(rest, {new_bet_id, new_user_id, new_odd, new_stake})
    ]
  end
end
