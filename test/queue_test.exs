# defmodule QueueTest do
#   use ExUnit.Case
#   doctest Queue
#
#   test "Enqueue one element" do
#     process = :uno
#     Queue.start_link process, 2
#     Queue.put process, 1
#     assert 1 == Queue.get process
#   end
#
#   test "The queue gets full" do
#     process = :dos
#     Queue.start_link process, 2
#     Queue.put process, 1
#     Queue.put process, 2
#     assert catch_exit(Queue.put :dos, 3)
#   end
#
#   test "The queue gets full and one element get released" do
#     process = :tres
#
#     Queue.start_link process, 2
#     Queue.put process, 1
#     Queue.put process, 2
#
#     spawn fn ->
#       :timer.sleep(100)
#       Queue.get process
#     end
#
#     Queue.put process, 3
#     assert Queue.get(process) == 3
#   end
#
#   test "The queue gets full by two elements" do
#     process = :cuatro
#
#     Queue.start_link process, 2
#     Queue.put process, 1
#     Queue.put process, 2
#
#     spawn fn ->
#       Queue.put process, 3
#     end
#     spawn fn ->
#       Queue.put process, 4
#     end
#     spawn fn ->
#       Queue.get process
#       Queue.get process
#       Queue.get process
#     end
#
#     :timer.sleep(100)
#
#     Queue.put process, 33
#     assert Queue.get(process) == 33
#   end
# end



defmodule QueueTestProducerConsumer do
  use ExUnit.Case
  doctest Queue

  test "Producer and consumer" do
    {:ok, queue} = Queue.start_link :cola1, 10
    consumers = 0
    amount = 1000000

    parent = self

    if consumers > 0 do
      1..consumers |> Enum.each(fn(_) ->
        spawn fn ->
          consumer(queue)
          send parent, :ok
        end
      end)
    end
    
    producer(queue, amount)

    if consumers > 0 do
      1..consumers |> Enum.each(fn(_) ->
        Queue.put queue, :ok
      end)
    end

    1..consumers |> Enum.each(fn(_) ->
      receive do: (:ok -> :ok)
    end)

    IO.inspect Queue.state(queue)
  end

  def producer(queue, amount) do
    1..amount |> Enum.each(fn(x) ->
      Queue.put queue, x
      IO.inspect Queue.state queue
    end)
  end

  def consumer(queue) do
    val = Queue.get queue
    IO.puts "read: #{inspect self} #{inspect val}"
    if val != :ok, do: consumer(queue)
  end
end
