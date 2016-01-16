defmodule QueueTest do
  use ExUnit.Case
  doctest Queue

  test "Enqueue one element" do
    process = :uno
    Queue.start_link process, 2
    Queue.put process, 1
    assert 1 == Queue.get process
  end

  test "The queue gets full" do
    process = :dos
    Queue.start_link process, 2
    Queue.put process, 1
    Queue.put process, 2
    assert catch_exit(Queue.put :dos, 3)
  end

  test "The queue gets full and one element get released" do
    process = :tres

    Queue.start_link process, 2
    Queue.put process, 1
    Queue.put process, 2

    spawn fn ->
      :timer.sleep(100)
      Queue.get process
    end

    Queue.put process, 3
    assert Queue.get(process) == 3
  end

  test "The queue gets full by two elements" do
    process = :cuatro

    Queue.start_link process, 2
    Queue.put process, 1
    Queue.put process, 2

    spawn fn ->
      Queue.put process, 3
    end
    spawn fn ->
      Queue.put process, 4
    end
    spawn fn ->
      Queue.get process
      Queue.get process
      Queue.get process
    end

    :timer.sleep(100)

    Queue.put process, 33
    assert Queue.get(process) == 33
  end

end
