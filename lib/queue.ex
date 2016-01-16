defmodule Queue do
  use GenServer

  defmodule State do
    defstruct capacity: 0, writers: [], readers: [], work: []
  end

  def start_link(name, capacity) do
    GenServer.start_link __MODULE__, capacity, name: name
  end

  def init(capacity) do
    IO.inspect "--> #{capacity}"
    {:ok, %Queue.State{capacity: capacity}}
  end

  def put(name, new_work) do
    GenServer.call name, {:put, new_work}
  end

  def get(name) do
    GenServer.call name, :get
  end

  def state(name) do
    GenServer.call name, :state
  end

  # Get.
  def handle_call(:get, from, state) do
    case get_work(from, state.work, state.readers, state.writers, state.capacity) do
      {:noreply, readers} ->
        new_state = %State{state | readers: readers}
        {:noreply, new_state}
      {:reply, work_to_do, work, readers, writers} ->
        new_state = %State{state | work: work, readers: readers, writers: writers}
        {:reply, work_to_do, new_state}
    end
  end

  # Put.
  def handle_call({:put, new_work}, from, state) do
    case put_work(from, new_work, state.writers, state.readers, state.work, state.capacity) do
      {:reply, readers, writers, work} ->
        new_state = %State{state | work: work, readers: readers, writers: writers}
        IO.inspect new_state
        {:reply, :ok, new_state}
      {:noreply, readers, writers, work} ->
        new_state = %State{state | work: work, readers: readers, writers: writers}
        IO.inspect new_state
        {:noreply, new_state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  #-- Get ----------------------------------------------------------------------
  defp get_work(from, work, readers, writers, capacity) do
    if Enum.empty?(work) do
      readers = [from | readers]
      {:noreply, readers}
    else
      [old_work | work] = work
      if not Enum.empty?(writers) and length(work) < capacity do
        [{writer, writer_work} | writers] = writers
        work = [writer_work | work]
        GenServer.reply writer, :ok
      end
      {:reply, old_work, work, readers, writers}
    end
  end


  #-- Put ----------------------------------------------------------------------

  # Put work on the queue.
  defp put_work(from, new_work, writers, readers, work, capacity) do
    if not Enum.empty?(readers) do
      [reader | readers] = readers
      GenServer.reply reader, new_work
      {:reply, readers, writers, work}
    else
      if length(work) < capacity do
        work = [new_work | work]
        {:reply, readers, writers, work}
      else
        writers = [{from, new_work} | writers]
        {:noreply, readers, writers, work}
      end
    end
  end
end
