defmodule BetUnfair.MarketServer do
  use GenServer

  def start_link(name, description) do
    CubDB.start_link(data_dir: "./data/" <> name, name: :db)
    CubDB.put_new(:db, :description, description)
    GenServer.start_link(__MODULE__, :ok, name: :market)
  end

  def init(:ok) do
    {:ok, %{}}
  end
end
