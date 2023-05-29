
Benchee.run(%{
  "market_create_rmw_win" => fn ->
    BetUnfair.Server.start_link("test_db")
    BetUnfair.Server.market_create("rmw", "victoria")
    BetUnfair.Server.clean("test_db")
    end,

})
{:ok, list} = BetUnfair.Server.market_list()
Enum.each(list, fn x -> IO.puts(x) end)
