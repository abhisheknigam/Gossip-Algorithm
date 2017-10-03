defmodule PUSHSUM do
  use GenServer

  def start_link(args) do
     IO.puts "Inside start_link"
     #IO.inspect elem(args,0)
     node_name = "node_" <> Integer.to_string(elem(args,0))
     #IO.puts node_name
     {:ok, bucket} = GenServer.start_link(__MODULE__, [args], name: String.to_atom(node_name)) |> IO.puts
  end

  
end
