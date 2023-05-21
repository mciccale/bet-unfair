defmodule BetUnfair.DynamicSupervisor do
  use DynamicSupervisor

  @impl true
  def init(:ok) do
    children = [
      {DynamicSupervisor, name: __MODULE__}
    ]
  end
end
