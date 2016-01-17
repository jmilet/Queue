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
    producers = 1
    consumers = 20
    amount = 100
    {:ok, queue} = Queue.start_link :queue, 100
    {:ok, accumulator} = Queue.start_link :accumulator, amount + consumers

    parent = self()

    if consumers > 0 do
      1..consumers |> Enum.each(fn(_) ->
        spawn fn ->
          consumer(parent, queue, accumulator)
        end
      end)
    end

    1..producers |> Enum.each(fn(_) ->
      spawn fn-> producer(queue, amount, consumers) end
    end)

    if consumers > 0 do
      1..consumers |> Enum.each(fn(_) ->
        receive do: (:ok -> :ok)
      end)
    end

    IO.inspect Queue.state(queue)
    IO.inspect Queue.state(accumulator)

  end

  def producer(queue, amount, consumers) do
    1..amount |> Enum.each(fn(x) ->
      Queue.put queue, x
      # IO.inspect Queue.state queue
    end)
    1..consumers |> Enum.each(fn(_) ->
      Queue.put queue, :ok
    end)
  end

  def consumer(parent, queue, accumulator) do
    val = Queue.get queue
    IO.inspect val
    if val != :ok do
      Queue.put accumulator, "read: #{inspect self} #{inspect val}"
    end
    if val != :ok do
      consumer(parent, queue, accumulator)
    else
      send parent, :ok
    end
  end
end
