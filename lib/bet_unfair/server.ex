defmodule BetUnfair.Server do
  @moduledoc """
  A betting exchange system that allows users to place bets on different markets.
  """
  use GenServer


  # User types specification
  @type user_id :: String.t()
  @type user_info :: %Structs.UserInfo{name: String.t(), id: user_id(), balance: integer()}

  # Market types specification
  @type market_id :: String.t()
  @type market_info :: %Structs.MarketInfo{
          name: String.t(),
          description: String.t(),
          status: :active | :frozen | :cancelled | {:settled, boolean()}
        }

  # Bet types specification
  @type bet_id :: integer()
  @type bet_odd :: {pos_integer(), bet_id()}
  @type bet_info :: %Structs.BetInfo{
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

    # Trata el caso de que sea vacía la lista y devuelve 0
    bet_id = CubDB.select(bets_db) |> Enum.to_list() |> Enum.max(&>=/2, fn -> 0 end)

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
  @spec user_create(id :: String.t(), name :: String.t()) :: {:ok, user_id()} | {:error, :exists}
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

  @spec market_alive?(name :: String.t()) :: :ok | :error
  def market_alive?(name) do
    case GenServer.call(:bet_unfair, {:market_alive?, name}) do
      {:ok, market_pid} -> GenServer.call(market_pid, :alive?)
      :error -> :error
    end
  end

  @spec market_list() :: {:ok, [market_id()]}
  def market_list() do
    GenServer.call(:bet_unfair, :market_list)
  end

  @spec market_list_active() :: {:ok, [market_id()]}
  def market_list_active() do
    GenServer.call(:bet_unfair, :market_list_active)
  end

  @spec market_cancel(id :: market_id()) :: :ok | :error
  def market_cancel(id) do
    case GenServer.call(:bet_unfair, {:market_cancel, id}) do
      {:ok, market_pid, users_db} -> GenServer.call(market_pid, {:market_cancel, users_db})
      :error -> :error
    end
  end

  @spec market_freeze(id :: market_id()) :: :ok | :error
  def market_freeze(id) do
    case GenServer.call(:bet_unfair, {:market_freeze, id}) do
      {:ok, market_pid, users_db} -> GenServer.call(market_pid, {:market_freeze, users_db})
      :error -> :error
    end
  end

  @spec market_settle(id :: market_id(), result :: boolean()) :: :ok | :error
  def market_settle(id, result) do
    case GenServer.call(:bet_unfair, {:market_settle, id, result}) do
      {:ok, market_pid, users_db} ->
        GenServer.call(market_pid, {:market_settle, result, users_db})

      :error ->
        :error
    end
  end

  @spec market_bets(id :: market_id()) :: {:ok, Enum.t(bet_id())} | :error
  def market_bets(id) do
    case GenServer.call(:bet_unfair, {:market_bets, id}) do
      {:ok, market_pid} -> GenServer.call(market_pid, :market_bets)
      :error -> :error
    end
  end

  @spec market_pending_backs(id :: market_id()) :: {:ok, Enum.t(bet_odd())} | :error
  def market_pending_backs(id) do
    case GenServer.call(:bet_unfair, {:market_pending, id}) do
      {:ok, market_pid} -> GenServer.call(market_pid, :market_pending_backs)
      :error -> :error
    end
  end

  @spec market_pending_lays(id :: market_id()) :: {:ok, Enum.t(bet_odd())} | :error
  def market_pending_lays(id) do
    case GenServer.call(:bet_unfair, {:market_pending, id}) do
      {:ok, market_pid} -> GenServer.call(market_pid, :market_pending_lays)
      :error -> :error
    end
  end

  @spec market_get(id :: market_id()) :: {:ok, market_info()} | :error
  def market_get(id) do
    case GenServer.call(:bet_unfair, {:market_get, id}) do
      {:ok, market_pid} -> GenServer.call(market_pid, :market_get)
      :error -> :error
    end
  end

  @spec market_match(id :: market_id()) :: :ok | :error
  def market_match(id) do
    case GenServer.call(:bet_unfair, {:market_match, id}) do
      {:ok, market_pid} -> GenServer.call(market_pid, :market_match)
      :error -> :error
    end
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
      {:ok, market_pid, user_db, bets_db, bet_id} ->
        GenServer.call(market_pid, {:bet_back, user_id, stake, odds, user_db, bets_db, bet_id})

      :error ->
        :error
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
      {:ok, market_pid, user_db, bets_db, bet_id} ->
        GenServer.call(market_pid, {:bet_lay, user_id, stake, odds, user_db, bets_db, bet_id})

      :error ->
        :error
    end
  end

  @spec bet_cancel(id :: bet_id()) :: :ok | :error
  def bet_cancel(id) do
    case GenServer.call(:bet_unfair, {:bet_cancel, id}) do
      {:ok, market_pid, users_db} -> GenServer.call(market_pid, {:bet_cancel, id, users_db})
      :error -> :error
    end
  end

  @spec bet_get(id :: bet_id()) :: {:ok, bet_info()} | :error
  def bet_get(id) do
    case GenServer.call(:bet_unfair, {:bet_get, id}) do
      {:ok, market_pid} -> GenServer.call(market_pid, {:bet_get, id})
      :error -> :error
    end
  end
end