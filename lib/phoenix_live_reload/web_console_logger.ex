defmodule Phoenix.LiveReloader.WebConsoleLogger do
  @moduledoc false
  use GenServer
  import OurInspectUtils

  @registry Phoenix.LiveReloader.WebConsoleLoggerRegistry
  @compile {:no_warn_undefined, {Logger, :default_formatter, 0}}

  def registry, do: @registry

  def attach_logger do
    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.attach_logger"

    if function_exported?(Logger, :default_formatter, 0) do
      :ok =
        :logger.add_handler(__MODULE__, __MODULE__, %{
          formatter: Logger.default_formatter(colors: [enabled: false])
        })
    end
  end

  def detach_logger do
    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.detach_logger"

    if function_exported?(Logger, :default_formatter, 0) do
      :ok = :logger.remove_handler(__MODULE__)
    end
  end

  def subscribe(prefix) do
    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.subscribe #{ inspect( prefix)}"

    {:ok, _} = Registry.register(@registry, :all, prefix)
    :ok
  end

  def start_link(opts \\ []) do
    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.start_link opts: #{ inspect( opts)}"

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.init opts: #{ inspect( opts)}"

    # We need to trap exits so that we receive the `terminate/2` callback during
    # a graceful shutdown
    Process.flag(:trap_exit, true)

    attach_logger()

    {:ok, opts}
  end

  @impl GenServer
  def terminate(reason, state) do
    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.terminate reason: #{ inspect( reason)}; state: #{ inspect( state)}"

    # On shutdown we need to detach the logger before the Registry stops
    detach_logger()
    {:ok, state}
  end

  # Erlang/OTP log handler
  def log(%{meta: meta, level: level} = event, config) do
    %{formatter: {formatter_mod, formatter_config}} = config
    iodata = formatter_mod.format(event, formatter_config)
    msg = IO.iodata_to_binary(iodata)

    color_puts light_green: "### #{ inspect( self())}: WebConsoleLogger.log"
    color_puts light_green: "##### event: #{ inspect( event)}"

    Registry.dispatch(@registry, :all, fn entries ->
      event = %{level: level, msg: msg, file: meta[:file], line: meta[:line]}

      color_puts light_green: "##### entries: #{ inspect( entries)}"

      for {pid, prefix} <- entries do
        send(pid, {prefix, event})
      end
    end)
  end
end
