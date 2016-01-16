defmodule QueueTest do
  use ExUnit.Case
  doctest Queue

  test "Enqueue one element" do
    Queue.start_link :uno, 10
    Queue.put :uno, :test
    assert :test == Queue.get :uno
  end

  test "The queue gets full" do
    Queue.start_link :dos, 2
    Queue.put :dos, :uno
    Queue.put :dos, :dos
    assert catch_exit(Queue.put :dos, :tres)
  end

  test "The queue gets full and one element get released" do
    Queue.start_link :dos, 2

    Queue.put :dos, 1
    Queue.put :dos, 2
    spawn fn ->
      :timer.sleep(200)
      Queue.get :dos
    end
    Queue.put :dos, 3
    assert Queue.get(:dos) == 3
  end

end
