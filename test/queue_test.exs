defmodule QueueTestProducerConsumer do
  use ExUnit.Case
  doctest Queue


  test "The waiting writer is removed" do
    {:ok, queue} = Queue.start_link :queue, 0
    spawn fn ->
      spawn_link fn ->
        :timer.sleep 100
        1/0
      end
      Queue.put queue, 1
    end

    :timer.sleep 200

    assert %Queue.State{writers: []} == Queue.state queue
  end

  test "The waiting reader is removed" do
    {:ok, queue} = Queue.start_link :queue, 0
    spawn fn ->
      spawn_link fn ->
        :timer.sleep 100
        1/0
      end
      Queue.get queue
    end

    :timer.sleep 200

    assert %Queue.State{readers: []} == Queue.state queue
  end

  test "Producer and consumer" do
    producers = 1
    consumers = 20
    amount = 10
    {:ok, queue} = Queue.start_link :queue, 1
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

    assert Enum.empty?(Queue.state(queue).work)
    assert length(Queue.state(queue).readers) == 0
    assert length(Queue.state(queue).writers) == 0

    assert length(Queue.state(accumulator).work) == amount
    assert length(Queue.state(accumulator).readers) == 0
    assert length(Queue.state(accumulator).writers) == 0
  end

  def producer(queue, amount, consumers) do
    1..amount |> Enum.each(fn(x) ->
      Queue.put queue, x
    end)
    1..consumers |> Enum.each(fn(_) ->
      Queue.put queue, :ok
    end)
  end

  def consumer(parent, queue, accumulator) do
    val = Queue.get queue
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
