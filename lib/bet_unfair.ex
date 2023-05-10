defmodule BetUnfair do
  use GenServer
  @moduledoc """
  A betting exchange system that allows users to place bets on different markets.
  """

  # User types specification
  @type user_id :: String.t()
  @type user_info :: %{name: String.t(), id: user_id(), balance: integer()}

  # Market types specification
  @type market_id :: String.t()
  @type market_info :: %{name: String.t(), description: String.t(), status: :active | :frozen | :cancelled | {:settled, boolean()}}

  # Bet types specification
  @type bet_id :: integer()
  @type bet_odd :: {pos_integer(), bet_id()}
  @type bet_info :: %{odds: pos_integer(),
                      bet_type: :back | :lay,
                      market_id: market_id(),
                      user_id: user_id(),
                      original_stake: pos_integer(),
                      remaining_stake: pos_integer(),
                      matched_bets: [bet_id()],
                      status: :active |
                              :cancelled |
                              :market_cancelled |
                              {:market_settled, boolean()}}

  # State?

  # Private methods
  def insert_ordered([], bet), do: [bet]
  def insert_ordered([{bet_id, user_id, odd, stake} | rest], {new_bet_id, new_user_id, new_odd, new_stake}) when new_odd < odd do
	  [{new_bet_id, new_user_id, new_odd, new_stake} | [{bet_id, user_id, odd, stake} | rest]]
  end
  def insert_ordered([{bet_id, user_id, odd, stake} | rest], {new_bet_id, new_user_id, new_odd, new_stake}) do
	  [{bet_id, user_id, odd, stake} | insert_ordered(rest,{new_bet_id, new_user_id, new_odd, new_stake})]
  end

  def init(_) do
    {:ok, []}
  end

  # Exchange interaction
  #@spec start_link(name :: String.t()) :: {:ok, pid()}
  def start_link(name) do
    # Open a previous DB
    {:ok, dets} = :dets.open_file("./data/" <> name <> ".dets", [])

    # Transform it into ETS
    :ets.from_dets(:ets.new(:state, [:set, :public, {:keypos, 1}, :named_table]), dets)

    # Check if it was empty
    case :ets.tab2list(:state) do
      # If newly created, create the map for the users
      [] -> :ets.insert(:state, {:users, %{}})
    end

    # Start the server
    GenServer.start_link(BetUnfair, [], name: :bet_unfair)
  end

  @spec stop() :: :ok
  def stop() do
    #:dets.from_ets(
    #  :dets.open_file("./data/" <> name <> ".dets", [])
    #)
    GenServer.stop(:bet_unfair)
  end

  @spec clean(name :: String.t()) :: :ok
  def clean(name) do
    File.rm("./data/" <> name <> ".dets")
    GenServer.stop(String.to_atom(name))
  end

  # User interaction
  @spec user_create(id :: String.t(), name :: String.t()) :: {:ok, user_id()} | :error
  def user_create(id, name) do
    {:ok, id}
  end

  @spec user_deposit(id :: user_id(), amount :: pos_integer()) :: :ok | :error
  def user_deposit(id, amount) do
    # TODO
    :ok
  end

  @spec user_withdraw(id :: user_id(), amount :: pos_integer()) :: :ok | :error
  def user_withdraw(id, ammount) do
    # TODO
    :ok
  end

  @spec user_get(id :: user_id()) :: {:ok, user_info()} | :error
  def user_get(id) do
    # TODO
    {:ok, %{name: "Rama", id: id, balance: 0}}
  end

  @spec user_bets(id :: user_id()) :: Enum.t(bet_id()) | :error
  def user_bets(id) do
    # TODO
    [0]
  end

  # Market interaction
  @spec market_create(name :: String.t(), description :: String.t()) :: {:ok, market_id()} | :error
  def market_create(name, description) do
    # TODO
    {:ok, "Market1"}
  end

  @spec market_list() :: {:ok, [market_id()]} | :error
  def market_list() do
    # TODO
    {:ok, ["Market1"]}
  end

  @spec market_list_active() :: {:ok, [market_id()]} | :error
  def market_list_active() do
    # TODO
    {:ok, ["Market1"]}
  end

  @spec market_cancel(id :: market_id()):: :ok | :error
  def market_cancel(id) do
    # TODO
    :ok
  end

  @spec market_freeze(id :: market_id()):: :ok | :error
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

  @spec market_match(id :: market_id()):: :ok | :error
  def market_match(id) do
    :ok
  end

  # Bet interaction
  @spec bet_back(user_id :: user_id(), market_id :: market_id(), stake :: pos_integer(), odds :: pos_integer()) :: {:ok, bet_id()} | :error
  def bet_back(id, market_id, stake, odds) do
    # TODO
    {:ok, 0}
  end

  @spec bet_lay(user_id :: user_id(), market_id :: market_id(), stake :: pos_integer(), odds :: pos_integer()) :: {:ok, bet_id()} | :error
  def bet_lay(id, market_id, stake, odds) do
    # TODO
    {:ok, 0}
  end

  @spec bet_cancel(id :: bet_id()):: :ok | :error
  def bet_cancel(id) do
    # TODO
    :ok
  end

  @spec bet_get(id :: bet_id()) :: {:ok, bet_info()} | :error
  def bet_get(id) do
    # TODO
    {:ok, %{bet_type: :back,
            market_id: "Market1",
            user_id: "DNI-1234",
            odds: 150,
            original_stake: 2000,
            remaining_stake: 1500,
            matched_bets: [0,1,2],
            status: :active}}
  end
end
