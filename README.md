# Queue

Queue is a blocking FIFO queue implemented as an Elixir process.

It can be used like this:

```Elixir
{:ok, _pid} = Queue.start_link :queue, 20
Queue.put :queue, "element"
val = Queue.get :queue
IO.inspect Queue.state queue
```

It monitors process while being waiting for writing into or reading from the queue.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add queue to your list of dependencies in `mix.exs`:

        def deps do
          [{:queue, "~> 0.0.1"}]
        end

  2. Ensure queue is started before your application:

        def application do
          [applications: [:queue]]
        end
