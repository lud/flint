defmodule BitFlags do
  defp raise_invalid(message) do
    raise ArgumentError, message
  end

  @doc false
  def check_list_of_atoms(flags) when is_list(flags) do
    flags
    |> Enum.reject(&is_atom/1)
    |> case do
      [] -> :ok
      invalid -> raise_invalid_flags(invalid)
    end
  end

  def check_list_of_atoms(invalid) do
    raise_invalid_flags(invalid)
  end

  @doc false
  @spec raise_invalid_guard(term, term) :: no_return()
  def raise_invalid_guard(name, code) do
    raise_invalid(
      "invalid use of flags macro #{name}/1 in guard, " <>
        "expected an argument in the form of `variable.key` " <>
        "got: #{Macro.to_string(code)}"
    )
  end

  @doc false
  @spec raise_invalid_call(term, term) :: no_return()
  def raise_invalid_call(name, code) do
    raise_invalid(
      "invalid use of flags macro #{name}/1," <>
        "expected an argument in the form of `variable.key` " <>
        "got: `#{Macro.to_string(code)}`. " <>
        "Use the #{name}/2 function instead"
    )
  end

  @doc false
  @spec raise_invalid_key(term, term, term) :: no_return()
  def raise_invalid_key(name, key, code) do
    raise_invalid(
      "invalid use of flags macro #{name}/1, " <>
        "unknown flag key #{inspect(key)} in `#{Macro.to_string(code)}`"
    )
  end

  @spec raise_invalid_flags(term) :: no_return()
  defp raise_invalid_flags(invalid) do
    raise_invalid("defflags only accepts a list of atoms, got: #{inspect(invalid)}")
  end

  defmacro defflags(name, flagnames) when is_atom(name) do
    quote bind_quoted: binding(), generated: true, location: :keep do
      :ok = BitFlags.check_list_of_atoms(flagnames)

      kpow =
        flagnames
        |> Enum.with_index()
        |> Enum.map(fn {atom, pos} -> {atom, trunc(:math.pow(2, pos))} end)
        |> Enum.filter(fn {atom, _pos} -> atom != :_ end)
        |> Map.new()

      defmacro unquote(name)({{:., _, [{flags_name, _, _} = flags, key]}, _, _})
               when key in unquote(flagnames) do
        pow = Map.fetch!(unquote(Macro.escape(kpow)), key)

        quote do
          is_integer(unquote(flags)) and
            Bitwise.band(unquote(flags), unquote(pow)) == unquote(pow)
        end
      end

      defmacro unquote(name)({{:., _, [{flags_name, _, _} = flags, key]}, _, _} = code)
               when is_atom(key) do
        BitFlags.raise_invalid_key(unquote(name), key, code)
      end

      defmacro unquote(name)(code) do
        if Macro.Env.in_guard?(__CALLER__) do
          BitFlags.raise_invalid_guard(unquote(name), code)
        else
          BitFlags.raise_invalid_call(unquote(name), code)
        end
      end

      dynamic_guard = :"is_#{name}"

      defmacro unquote(dynamic_guard)(flags, key) do
        flagnames = unquote(flagnames)
        kpow = unquote(Macro.escape(kpow))

        quote do
          is_integer(unquote(flags)) and
            is_atom(unquote(key)) and
            unquote(key) in unquote(flagnames) and
            0 !=
              Bitwise.band(
                unquote(flags),
                :erlang.map_get(unquote(key), unquote(Macro.escape(kpow)))
              )
        end
      end

      def unquote(name)(), do: unquote(Macro.escape(kpow))

      @spec unquote(name)(flags :: non_neg_integer, key :: atom) :: boolean
      def unquote(name)(flags, key)

      @spec unquote(name)(
              flags :: non_neg_integer,
              key :: atom,
              new_value :: boolean | :toggle
            ) ::
              non_neg_integer
      def unquote(name)(flags, key, bool_or_toggle)

      for {atom, pow} <- kpow, atom != :_ do
        def unquote(name)(flags, unquote(atom)) when is_integer(flags) do
          Bitwise.band(flags, unquote(pow)) != 0
        end

        def unquote(name)(flags, unquote(atom), true) when is_integer(flags) do
          Bitwise.bor(flags, unquote(pow))
        end

        def unquote(name)(flags, unquote(atom), false) when is_integer(flags) do
          Bitwise.band(flags, Bitwise.bnot(unquote(pow)))
        end
      end

      def unquote(name)(flags, key, :toggle) when key in unquote(flagnames) do
        unquote(name)(flags, key, not unquote(name)(flags, key))
      end
    end
  end
end
