defmodule BetUnfair.MarketServer do
  use GenServer

  def start_link(name, description) do
    {:ok, pid} = CubDB.start_link(data_dir: "./data/" <> name, auto_file_sync: true)
    CubDB.put_new(pid, :description, description)
    GenServer.start_link(__MODULE__, pid, name: String.to_atom(name))
  end

  def init(pid) do
    {:ok, pid}
  end
end
