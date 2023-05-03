defmodule BetUnfair do
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
  @type bet_info :: %{bet_type: :back | :lay,
                      market_id: market_id(),
                      user_id: user_id(),
                      odds: pos_integer(),
                      original_stake: pos_integer(),
                      remaining_stake: pos_integer(),
                      matched_bets: [bet_id()],
                      status: :active |
                              :cancelled |
                              :market_cancelled |
                              {:market_settled, boolean()}}

  # State?

  # Exchange interaction
  @spec start_link(name :: String.t()) :: {:ok, String.t()}
  def start_link(name) do
    # TODO
    {:ok, name}
  end

  @spec stop() :: :ok
  def stop do
    # TODO
    :ok
  end

  @spec clean(name :: String.t()) :: :ok
  def clean(name) do
    # TODO
    :ok
  end

  # User interaction
  @spec user_create(id :: String.t(), name :: String.t()) :: {:ok, user_id()}
  def user_create(id, name) do
    # TODO
    {:ok, id}
  end

  @spec user_deposit(id :: user_id(), amount :: pos_integer()) :: :ok
  def user_deposit(id, amount) do
    # TODO
    :ok
  end

  @spec user_withdraw(id :: user_id(), amount :: pos_integer()) :: :ok
  def user_withdraw(id, ammount) do
    # TODO
    :ok
  end

  @spec user_get(id :: user_id()) :: {:ok, user_info()}
  def user_get(id) do
    # TODO
    {:ok, %{name: "Rama", id: id, balance: 0}}
  end

  @spec user_bets(id :: user_id()) :: Enum.t(bet_id())
  def user_bets(id) do
    # TODO
    [0]
  end

  # Market interaction
  @spec market_create(name :: String.t(), description :: String.t()) :: {:ok, market_id()}
  def market_create(name, description) do
    # TODO
    {:ok, "Market1"}
  end

  @spec market_list() :: {:ok, [market_id()]}
  def market_list() do
    # TODO
    {:ok, ["Market1"]}
  end

  @spec market_list_active() :: {:ok, [market_id()]}
  def market_list_active() do
    # TODO
    {:ok, ["Market1"]}
  end

  @spec market_cancel(id :: market_id()):: :ok
  def market_cancel(id) do
    # TODO
    :ok
  end

  @spec market_freeze(id :: market_id()):: :ok
  def market_freeze(id) do
    # TODO
    :ok
  end

  @spec market_settle(id :: market_id(), result :: boolean()) :: :ok
  def market_settle(id, result) do
    # TODO
    :ok
  end

  @spec market_bets(id :: market_id()) :: {:ok, Enum.t(bet_id())}
  def market_bets(id) do
    {:ok, [0]}
  end

  @spec market_pending_backs(id :: market_id()) :: {:ok, Enum.t(bet_odd())}
  def market_pending_backs(id) do
    # TODO
    {:ok, [{150, 0}]}
  end

  @spec market_pending_lays(id :: market_id()) :: {:ok, Enum.t(bet_odd())}
  def market_pending_lays(id) do
    # TODO
    {:ok, [{150, 0}]}
  end

  @spec market_get(id :: market_id()) :: {:ok, market_info()}
  def market_get(id) do
    # TODO
    {:ok, %{name: "Market1", description: "Soccer Market", status: :active}}
  end

  @spec market_match(id :: market_id()):: :ok
  def market_match(id) do
    :ok
  end

  # Bet interaction
  @spec bet_back(user_id :: user_id(), market_id :: market_id(), stake :: pos_integer(), odds :: pos_integer()) :: {:ok, bet_id()}
  def bet_back(id, market_id, stake, odds) do
    # TODO
    {:ok, 0}
  end

  @spec bet_lay(user_id :: user_id(), market_id :: market_id(), stake :: pos_integer(), odds :: pos_integer()) :: {:ok, bet_id()}
  def bet_lay(id, market_id, stake, odds) do
    # TODO
    {:ok, 0}
  end

  @spec bet_cancel(id :: bet_id()):: :ok
  def bet_cancel(id) do
    # TODO
    :ok
  end

  @spec bet_get(id :: bet_id()) :: {:ok, bet_info()}
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
