defmodule BetUnfair.Supervisor do
  use Supervisor

  def start_link(name, opts) do
    Supervisor.start_link(__MODULE__, name, opts)
  end

  @impl true
  def init(name) do
    children = [
      Supervisor.child_spec({BetUnfair.Server, name}, id: :bet_unfair),
      Supervisor.child_spec({BetUnfair.DynamicSupervisor, [max_child: 50]},
        id: :bet_unfair_dynamic_supervisor
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
