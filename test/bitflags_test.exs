defmodule BitFlagsTest do
  use ExUnit.Case
  require BitFlags

  @letters :lists.reverse([:e, :d, :c, :b, :a])
  BitFlags.defflags(:letter, @letters)

  test "create a predictible flag function" do
    @letters |> Enum.map(fn key -> refute letter(0, key) end)
    assert letter(0b00000001, :a)
    refute letter(0b00000000, :a)
    refute letter(0b11111110, :a)
    assert letter(3, :a) and letter(3, :b)
  end

  test "the generated macro is usable in guards" do
    assert :yep = is_letter_d(0b00001000)
    assert :nope = is_letter_d(0b00000000)
  end

  test "the generated macro is usable in code" do
    flags = 0b00001000
    assert letter(flags.d)
    refute letter(flags.a)
  end

  def is_letter_d(flags) when letter(flags.d), do: :yep
  def is_letter_d(flags) when not letter(flags.d), do: :nope

  test "invalid values" do
    some_string = "hello"
    assert :nope == is_letter_d("some_string")
    catch_error(letter(some_string, :d))
  end

  test "flag toggler" do
    flags = 0
    refute letter(flags, :c)

    flags_with_c = letter(flags, :c, true)
    assert letter(flags_with_c, :c)
    # idempotency
    assert letter(letter(flags_with_c, :c, true), :c)

    flags_no_c = letter(flags_with_c, :c, false)
    refute letter(flags_no_c, :c)
    # idempotency
    refute letter(letter(flags_with_c, :c, false), :c)

    flags_no_c2 = letter(flags_with_c, :c, :toggle)
    refute letter(flags_no_c2, :c)
  end

  test "dynamic guard" do
    assert :yep == dynamic(-1, :b)
    assert :nope == dynamic(0, :b)
  end

  def dynamic(flags, key) when is_letter(flags, key) do
    :yep
  end

  def dynamic(_, _) do
    :nope
  end

  test "usage of property call form" do
    flags = 0
    refute letter(flags.c)

    flags_with_c = letter(flags, :c, true)
    assert letter(flags_with_c.c)
  end
end
