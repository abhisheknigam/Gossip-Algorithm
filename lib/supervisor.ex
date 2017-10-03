defmodule Super do
  use Supervisor

  def main(args) do
      start_link()
  end

  def start_creating_nodes(n,total_node) do
      node_name = "node_" <> Integer.to_string(n)
      #IO.puts node_name
      Supervisor.start_child(__MODULE__,[{n, total_node}])
      if n > 1 do
        start_creating_nodes(n-1, total_node)
      end

      if(n ==1) do
        GenServer.call(String.to_atom("node_1"),{:receive_msg_pushsum, {0,1}})
      end
      IO.gets ""
  end 

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__) |> IO.inspect
    n= 15
    total_node = n
    start_creating_nodes(n,total_node)
  end

  def init(_arg) do
    children = [
      worker(MAIN, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

 

end