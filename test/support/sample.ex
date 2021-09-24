defmodule BitFlags.TestSample do
  @moduledoc false

  require BitFlags

  BitFlags.defflags(:sample, ~w(one two four eight)a)

  def dynamic(flags, key) when is_sample(flags, key) do
    :yep
  end

  def dynamic(_, _) do
    :nope
  end
end
