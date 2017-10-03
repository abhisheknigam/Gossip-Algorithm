defmodule MAIN do
  use GenServer
  
  def main(args) do
      IO.puts "Inside Main"
      start_link(args)
  end

  def start_link(args) do
     IO.puts "Inside start_link"
     node_name = "node_" <> Integer.to_string(elem(args,0))
     {:ok, bucket} = GenServer.start_link(__MODULE__, [args], name: String.to_atom(node_name)) |> IO.puts
  end

  defp ref(id) do
    {:global, {:nodeId, id}}
  end

  def send_message_start() do
    IO.puts "all nodes created"
    send_message("node_"<>Integer.to_string(5))
  end

  def init(args) do
    IO.inspect self()
    [a|b] = args 
    total_nodes = elem(a,1)
    node_id = elem(a,0)
    weight = 0

    map =  %{"id" => node_id,"total_nodes" => total_nodes, "neighbours" => [], "sum" => node_id, "weight"=> weight}    
    state = build_mesh_topology(map)

    IO.inspect state
    {:ok,state}
  end

  def mesh_list(node_id,cur_node_id,lst) when node_id<1 do
    lst
  end

  ## mesh topology
  def mesh_list(node_id,cur_node_id,lst) do
    if(node_id != cur_node_id) do 
      lst = [node_id|lst]
    end
     mesh_list(node_id-1,cur_node_id,lst)
  end

  def get_mesh_neighbours(node_id,cur_node_id) do
     mesh_list(node_id,cur_node_id,[])
  end

  def build_mesh_topology(state) do
    total_nodes = Map.get(state,"total_nodes")
    cur_node_id = Map.get(state,"id")
    neighbours = get_mesh_neighbours(total_nodes,cur_node_id)
    state = Map.put(state,"neighbours",neighbours)
    #IO.inspect state
    state
  end
  ##end mesh topology


   def get_line_neighbours(total_nodes,cur_node_id) do
    lst = []
    cond do
      cur_node_id == 1 -> lst = [cur_node_id + 1|lst]
      cur_node_id == 1 -> lst = [cur_node_id + 1|lst]
      true -> lst = [cur_node_id + 1|lst]
    end
    lst
  end
  
  
  def build_line_topology(state) do
    total_nodes = Map.get(state,"total_nodes")
    cur_node_id = Map.get(state,"id")
    neighbours = get_line_neighbours(total_nodes,cur_node_id)
    state = Map.put(state,"neighbours",neighbours)
    #IO.inspect state
    state
  end


  ## end line topology
  ## 2D grid

  def get_2D_neighbours(dimension,cur_node_id) do
    column_number = round :math.fmod cur_node_id,dimension
    top = cur_node_id - dimension
    lst = [] 
    if(top>0) do
      lst = [top|lst]
    end 
    down = cur_node_id + dimension
    if(down < dimension*dimension) do
      lst = [down|lst]
    end

    cond do
      column_number == 0 -> lst = [cur_node_id - 1|lst]
      column_number == 1 -> lst = [cur_node_id+1|lst]
      true -> lst = [cur_node_id - 1|lst]
      lst = [cur_node_id + 1|lst]
    end
    lst
  end

  def build_2D_topology(state) do
    total_nodes = Map.get(state,"total_nodes")
    dimension = round :math.ceil :math.sqrt(total_nodes)
    total_nodes = dimension*dimension
    Map.put(state,"total_nodes",total_nodes)
    IO.puts "total_nodes :::::" <> Integer.to_string total_nodes
    cur_node_id = Map.get(state,"id")
    neighbours = get_2D_neighbours(dimension,cur_node_id)
    state = Map.put(state,"neighbours",neighbours)
    #IO.inspect state
    state
  end

  ##2D grid ends
  ##imperfect 2D start

  def get_imperfect2D_neighbours(total_nodes,dimension,cur_node_id) do
    lst = get_2D_neighbours(dimension,cur_node_id)
    #add random node
    lst = [:rand.uniform(total_nodes)|lst]
    lst
  end

  def build_imperfect2D_topology(state) do
    total_nodes = Map.get(state,"total_nodes")
    dimension = round :math.ceil :math.sqrt(total_nodes)
    total_nodes = dimension*dimension
    Map.put(state,"total_nodes",total_nodes)

    cur_node_id = Map.get(state,"id")
    neighbours = get_imperfect2D_neighbours(total_nodes,dimension,cur_node_id)
    state = Map.put(state,"neighbours",neighbours)
    #IO.inspect state
    state
  end

  def send_message_pushsum(neighbours,tup) do
    if(length(neighbours) == 0) do
      #Process.exit(self(), :normal)
    else
      node_id = Enum.random(neighbours)
      node_name = "node_"<>Integer.to_string(node_id)
      pid  = Process.whereis(String.to_atom(node_name))
      
      if(pid != nil && Process.alive?(pid) == true) do
      GenServer.call(String.to_atom(node_name), {:receive_msg_pushsum, tup}) 
      else 
        neighbours = List.delete(neighbours,node_id)
        send_message_pushsum(neighbours,tup)
      end
    end
    :timer.sleep(150)
    #send_message_pushsum(neighbours, tup)
  end


  def send_message(neighbours) do

    if(length(neighbours) == 0) do
      Process.exit(self(), :normal) 
    end
    node_id = Enum.random(neighbours)
    node_name = "node_"<>Integer.to_string(node_id)
    pid  = Process.whereis(String.to_atom(node_name))
 
    if(pid != nil && Process.alive?(pid) == true) do
      GenServer.call(String.to_atom(node_name), {:receive_msg, "keyur here"})
    else 
      neighbours = List.delete(neighbours,node_id)
    end
  
    send_message(neighbours)
  end


  # server callbacks
  def handle_call({:send_message ,new_message},_from,state) do  
    IO.puts "got message::"<>new_message  
    IO.inspect self()
    GenServer.call(String.to_atom("node_8"), {:trial, "keyur next node"})
    {:reply,state,state}
  end

  def handle_call({:trial, msg}, _from, state) do
    IO.puts " new msg:"<>msg <> " :: from"
    IO.inspect state
    IO.inspect _from
    IO.inspect self()

    {:reply,state,state}
  end
 
  def handle_call({:receive_msg_pushsum, msg}, _from, state) do
     neighbours = Map.get(state,"neighbours") 
     
     #IO.inspect msg
     recieve_sum = elem(msg,0);
     recieve_weight = elem(msg,1);

     sum  = Map.get(state,"sum")
     weight = Map.get(state,"weight")

     previous_ratio = 1
     if(weight != 0) do
       previous_ratio = sum/weight
    end
     

     sum = sum + recieve_sum
     weight = weight + recieve_weight

     send_sum = sum/2
     send_weight = weight/2


     state = Map.put(state,"sum",send_sum)
     state = Map.put(state,"weight",send_weight)
    

     #if(Map.get(state,"send_msg_process") == nil) do
        send_msg_pid = spawn fn -> send_message_pushsum(neighbours, {send_sum,send_weight}) end 
        #state = Map.put(state,"send_msg_process",send_msg_pid)  
     #end

     ratio = send_sum/send_weight;
     #IO.inspect ratio

     if(Map.get(state,"ratio_count") == nil) do
       #IO.inspect "ratio count set true" 
       state = Map.put(state,"ratio_count",0)
     end

     current_ratio_count = Map.get(state,"ratio_count")

     #IO.inspect ratio
     #IO.inspect "current_ratio_count"
     #IO.inspect abs(previous_ratio - ratio)
     
     if(abs(previous_ratio - ratio) < 0.0000000001) do
       current_ratio_count = current_ratio_count + 1
       state = Map.put(state, "ratio_count", current_ratio_count)
       #IO.inspect "Smaller ratio"
       #IO.inspect current_ratio_count
     end

     if(abs(previous_ratio - ratio) > 0.0000000001) do
       #IO.inspect "reset_ratio"
       current_ratio_count = 0
       Map.put(state, "ratio_count", current_ratio_count)
     end

    if(current_ratio_count != nil && current_ratio_count >= 3) do
      IO.puts "kill process :: " <> Integer.to_string(Map.get(state,"id"))      
      Process.exit(self(), :normal)      
    end
    {:reply,state,state}
  end

end
