defmodule BetUnfair.DynamicSupervisor do
  use DynamicSupervisor, restart: :transient

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: :bet_unfair_dynamic_supervisor)
  end

  def start_child(name, description) do
    spec = %{
      id: String.to_atom(name),
      start: {BetUnfair.MarketServer, :start_link, [name, description]}
    }

    DynamicSupervisor.start_child(:bet_unfair_dynamic_supervisor, spec)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
