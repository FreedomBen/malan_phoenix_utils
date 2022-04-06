defmodule MalanPhoenixUtilsTest do
  alias MalanUtils, as: Utils

  use ExUnit.Case, async: true
  # use Malan.DataCase, async: true
  doctest MalanUtils

  defmodule TestStruct, do: defstruct([:one, :two, :three])

  describe "main" do
    test "#remove_not_loaded/1" do
      before = %{
        one: "one",
        two: "two",
        three: %Ecto.Association.NotLoaded{}
      }

      after_removed = %{
        one: "one",
        two: "two"
      }

      assert after_removed == Utils.remove_not_loaded(before)
    end
  end

  describe "DateTime" do
    # This exercises all of the adjust_yyy_time funcs since they call each other
    test "adjust_cur_time weeks" do
      adjusted = Utils.DateTime.adjust_cur_time(2, :weeks)
      manually = DateTime.add(DateTime.utc_now(), 2 * 7 * 24 * 60 * 60, :second)
      diff = DateTime.diff(manually, adjusted, :second)
      # Possibly flakey test. These numbers might be too close.
      # Changed 1 to 2, hopefully that is fuzzy enough to work
      assert diff >= 0 && diff < 2
    end

    test "adjust_time weeks" do
      # This exercises all of the adjust_time funcs since they call each other
      start_dt = DateTime.utc_now()

      assert DateTime.add(start_dt, 2 * 7 * 24 * 60 * 60, :second) ==
               Utils.DateTime.adjust_time(start_dt, 2, :weeks)
    end

    test "#in_the_past?/{1,2}" do
      cur_time = DateTime.utc_now()

      assert_raise(ArgumentError, ~r/past_time.*must.not.be.nil/, fn ->
        Utils.DateTime.in_the_past?(nil)
      end)

      assert false == Utils.DateTime.in_the_past?(Utils.DateTime.adjust_cur_time(1, :minutes))
      assert true == Utils.DateTime.in_the_past?(Utils.DateTime.adjust_cur_time(-1, :minutes))
      # exact same time shows as expired
      assert true == Utils.DateTime.in_the_past?(cur_time)

      assert true ==
               Utils.DateTime.in_the_past?(cur_time, Utils.DateTime.adjust_cur_time(1, :minutes))

      assert false ==
               Utils.DateTime.in_the_past?(cur_time, Utils.DateTime.adjust_cur_time(-1, :minutes))

      assert true == Utils.DateTime.in_the_past?(cur_time, cur_time)
    end

    test "#expired?/{1,2}" do
      cur_time = DateTime.utc_now()

      assert_raise(ArgumentError, ~r/expires_at.*must.not.be.nil/, fn ->
        Utils.DateTime.expired?(nil)
      end)

      assert false == Utils.DateTime.expired?(Utils.DateTime.adjust_cur_time(1, :minutes))
      assert true == Utils.DateTime.expired?(Utils.DateTime.adjust_cur_time(-1, :minutes))
      # exact same time shows as expired
      assert true == Utils.DateTime.expired?(cur_time)

      assert true ==
               Utils.DateTime.expired?(cur_time, Utils.DateTime.adjust_cur_time(1, :minutes))

      assert false ==
               Utils.DateTime.expired?(cur_time, Utils.DateTime.adjust_cur_time(-1, :minutes))

      assert true == Utils.DateTime.expired?(cur_time, cur_time)
    end
  end

  describe "Enum" do
    test "#none?" do
      input = ["one", "two", "three"]
      assert true == Utils.Enum.none?(input, fn i -> i == "four" end)
      assert false == Utils.Enum.none?(input, fn i -> i == "three" end)
    end
  end

  describe "Phoenix.Controller" do
  end

  describe "Ecto.Changeset" do
    test "#convert_changes/1" do
      ts = %TestStruct{one: "one", two: "two"}
      cs = Ecto.Changeset.change({ts, %{one: :string, two: :string}})

      assert %{ts | three: ts} ==
               Utils.Ecto.Changeset.convert_changes(%{ts | three: cs})
    end

    test "#convert_changes/1 handles arrays" do
      ts = %TestStruct{one: "one", two: "two"}
      cs = Ecto.Changeset.change({ts, %{one: :string, two: :string}})

      assert %{ts | three: [ts, ts]} ==
               Utils.Ecto.Changeset.convert_changes(%{ts | three: [cs, cs]})
    end

    test "#validate_ip_addr/2 allows valid address through" do
      types = %{one: :string, two: :string, three: :string}
      ts = %TestStruct{one: "one", two: "two"}

      cs =
        Ecto.Changeset.change({ts, types}, %{three: "1.1.1.1"})
        |> Utils.Ecto.Changeset.validate_ip_addr(:three)

      assert cs.valid?

      cs =
        Ecto.Changeset.change({ts, types}, %{three: "127.0.0.1"})
        |> Utils.Ecto.Changeset.validate_ip_addr(:three)

      assert cs.valid?

      cs =
        Ecto.Changeset.change({ts, types}, %{three: "255.255.255.255"})
        |> Utils.Ecto.Changeset.validate_ip_addr(:three)

      assert cs.valid?
    end

    test "#validate_ip_addr/2 adds error to changeset when not valid" do
      types = %{one: :string, two: :string, three: :string}
      ts = %TestStruct{one: "one", two: "two"}
      cs = Ecto.Changeset.change({ts, types}, %{three: "1.1.1"})
      assert cs.valid?
      cs = Utils.Ecto.Changeset.validate_ip_addr(cs, :three)
      assert not cs.valid?
    end

    test "#validate_ip_addr/3 accepts empty when flagged" do
      types = %{one: :string, two: :string, three: :string}
      ts = %TestStruct{one: "one", two: "two"}

      cs =
        Ecto.Changeset.change({ts, types}, %{three: ""})
        |> Utils.Ecto.Changeset.validate_ip_addr(:three, true)

      assert cs.valid?

      cs =
        Ecto.Changeset.change({ts, types}, %{three: ""})
        |> Utils.Ecto.Changeset.validate_ip_addr(:three)

      assert errors_on(cs).three == ["three must be a valid IPv4 or IPv6 address"]
    end
  end

  describe "IPv4" do
    test "works" do
      assert "1.1.1.1" == Utils.IPv4.to_s({1, 1, 1, 1})
      assert "127.0.0.1" == Utils.IPv4.to_s({127, 0, 0, 1})
    end
  end

  describe "FromEnv" do
    test "#log_str/2 :mfa",
      do:
        assert(
          "[Elixir.Malan.UtilsTest.#test FromEnv #log_str/2 :mfa/1]" ==
            Utils.FromEnv.log_str(__ENV__)
        )

    test "#log_str/2 :func_only",
      do:
        assert(
          "[Elixir.Malan.UtilsTest.#test FromEnv #log_str/2 :func_only/1]" ==
            Utils.FromEnv.log_str(__ENV__)
        )

    test "#log_str/1 defaults to :mfa",
      do: assert(Utils.FromEnv.log_str(__ENV__, :mfa) == Utils.FromEnv.log_str(__ENV__))

    test "#mfa_str/1",
      do:
        assert(
          "Elixir.Malan.UtilsTest.#test FromEnv #mfa_str/1/1" == Utils.FromEnv.mfa_str(__ENV__)
        )

    test "#func_str/1 env",
      do: assert("#test FromEnv #func_str/1 env/1" == Utils.FromEnv.func_str(__ENV__.function))

    test "#func_str/1 func",
      do: assert("#test FromEnv #func_str/1 func/1" == Utils.FromEnv.func_str(__ENV__))

    test "#mod_str/1", do: assert("Elixir.Malan.UtilsTest" == Utils.FromEnv.mod_str(__ENV__))
  end
end
