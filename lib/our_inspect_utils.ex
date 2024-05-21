defmodule OurInspectUtils do
  import Inspect.Algebra
  import Extructure

  @syntax_colors [
    atom: :cyan,
    boolean: :magenta,
    number: :yellow,
    regex: :yellow,
    string: :green,
    nil: :magenta
  ]

  @doc "To import and use as an `IO.inspect` :syntax_colors option."
  def syntax_colors() do
    @syntax_colors
  end

  @doc "Provides a uniform way for inspecting structure's select content."
  def inspect_struct( %{ __struct__: module} = term, opts, content) do
    if opts.custom_options[ :essentials] do
      module_name = module |> Module.split() |> Enum.join( ".")
      concat( [ "##{ module_name}<", to_doc( content, opts), ">"])
    else
      Inspect.Any.inspect( term, opts)
    end
  end

  @doc """
  IO.inspects a term while composing the label of as many differently
  colored chunks as necessary. The keys used in the keyword list
  should be ANSI color codes (e.g. :yellow, :light_yellow, :blue,
  :light_blue, ..)

  Ex:

  ```elixir
  color_inspect( :foo, yellow: inspect( self()) <> " ", green: "FOO")
  ```

  Supports appending colored text or plain string so, for instance,
  new lines can be added in a single call. Ex:

  ```elixir
  color_inspect( error, light_red: "returned error", append: "\n\n")
  ```
  or
  ```elixir
  color_inspect( error, light_red: "error", append: [ light_red: "\nNOTE!\n"])
  ```
  """
  @spec color_inspect( term(), keyword()) :: term()
  def color_inspect( term, colored) do
    if inspect?() do
      do_color_inspect( term, colored)
    else
      term
    end
  end

  @doc false
  @spec do_color_inspect( term(), keyword()) :: term()
  def do_color_inspect( term, colored) do
    [ _append | colored] <~ colored

    IO.inspect( term, label: colored_string( colored))

    cond do
      is_binary( append) ->
        IO.puts( append)

      is_list( append) ->
        color_puts( append)

      true ->
        :ok
    end

    term
  end

  @doc """
  Like `color_inspect.2` but for IO.puts.
  """
  @spec color_puts( keyword()) :: :ok
  def color_puts( colored) do
    if inspect?() do
      do_color_puts( colored)
    else
      :ok
    end
  end

  @doc false
  @spec do_color_puts( keyword()) :: :ok
  def do_color_puts( colored) do
    IO.puts( colored_string( colored))
  end

  # Returns a string in ansi colors as specified by the keyword list.
  @spec colored_string( keyword()) :: String.t()
  defp colored_string( colored) do
    colored_string =
      colored
      |> Enum.map( fn { color, msg} ->
        "#{ apply( IO.ANSI, color, [])}#{ msg}"
      end)
      |> Enum.join()

    "#{ colored_string}#{ IO.ANSI.light_white()}"
  end

  defp inspect?() do
    true
  end
end
