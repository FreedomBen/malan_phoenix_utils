defmodule MalanPhoenixUtils.IPv4 do
  def to_s(%Plug.Conn{} = conn), do: to_s(conn.remote_ip)
  def to_s(ip_tuple), do: MalanUtils.IPv4.to_s(ip_tuple)
end

defmodule MalanPhoenixUtils.Phoenix.Controller do
  import Plug.Conn, only: [halt: 1, put_status: 2]

  require Logger

  def halt_status(conn, status) do
    Logger.debug("[halt_status]: status: #{status}")

    conn
    |> put_status(status)
    |> Phoenix.Controller.put_view(MalanWeb.ErrorView)
    |> Phoenix.Controller.render("#{status}.json")
    |> halt()
  end

  def remote_ip_s(conn), do: MalanUtils.IPv4.to_s(conn.remote_ip)
end

defmodule MalanPhoenixUtils.Ecto do
  @doc ~S"""
  If any of the top-level properties are `Ecto.Association.NotLoaded`, remove them.

  Note that if `map` is actually a `struct` this won't work.  You should first convert
  it to a map:

  ```
  Map.from_struct(struct)
  ```
  """
  def remove_not_loaded(map) do
    Enum.filter(map, fn
      {_k, %Ecto.Association.NotLoaded{} = _v} -> false
      {_k, _v} -> true
    end)
    |> Enum.into(%{})
  end
end

defmodule MalanPhoenixUtils.Ecto.Query do
  defguard valid_sort(sort) when is_atom(sort) and sort in [:asc, :desc]
end

defmodule MalanPhoenixUtils.Ecto.Changeset do
  @doc """
  Validates that the property specified does NOT match the provided regex.

  This function is essentially the opposite of validate_format()
  """
  def validate_not_format(nil, _regex), do: false
  def validate_not_format(value, regex), do: value =~ regex

  def validate_not_format(changeset, property, regex) do
    case validate_not_format(Map.get(changeset.changes, property), regex) do
      true -> Ecto.Changeset.add_error(changeset, property, "has invalid format")
      false -> changeset
    end
  end

  def validate_ip_addr(changeset, property, allow_empty? \\ false) do
    val = Ecto.Changeset.get_change(changeset, property)

    cond do
      allow_empty? && val == "" ->
        changeset

      Iptools.is_ipv4?(val) ->
        changeset

      true ->
        Ecto.Changeset.add_error(
          changeset,
          property,
          "#{property} must be a valid IPv4 or IPv6 address"
        )
    end
  end

  @doc ~S"""
  Convert changeset errors into a list of `String`s

  ## Examples

      MalanPhoenixUtils.Ecto.Changeset.errors_to_str_list(changeset)
      # TODO example needs updated
      [who: {"who must be a valid ID of a user", []}]
  """
  def errors_to_str_list(%Ecto.Changeset{errors: errors}),
    do: errors_to_str_list(errors)

  def errors_to_str_list(errors) do
    Enum.map(errors, fn
      {field, {err_msg, _attrs}} -> "#{field}: #{err_msg}"
    end)
  end

  @doc ~S"""
  Convert changeset errors into a `String`

  ## Examples

      MalanPhoenixUtils.Ecto.Changeset.errors_to_str_list(changeset)
      # TODO example needs updated
      [who: {"who must be a valid ID of a user", []}]
  """
  def errors_to_str(%Ecto.Changeset{} = changeset) do
    errors_to_str_list(changeset)
    |> Enum.join(", ")
  end

  def errors_to_str(:too_many_requests) do
    "Rate limit exceeded"
  end

  @doc ~S"""
  If any of the top-level keys in `data` are `Ecto.Changeset`s, apply their changes.

  This is not recursive.  It onliy does the top level.  Also changes are applied
  whether they are valid or not, so consider whether that's the behavior you want.
  """
  def convert_changes(%Ecto.Changeset{changes: changes}), do: convert_changes(changes)

  def convert_changes(%{__struct__: struct_type} = data) do
    data
    |> Map.from_struct()
    |> convert_changes(struct_type)
  end

  def convert_changes(%{} = data) do
    data
    |> Enum.map(fn
      {k, %Ecto.Changeset{} = v} ->
        {k, Ecto.Changeset.apply_changes(v)}

      {k, va} when is_list(va) ->
        {k,
         Enum.map(va, fn
           %Ecto.Changeset{} = v -> Ecto.Changeset.apply_changes(v)
           v -> v
         end)}

      {k, v} ->
        {k, v}
    end)
    |> Enum.into(%{})
  end

  def convert_changes(data), do: data

  def convert_changes(data, struct_type) do
    struct(struct_type, convert_changes(data))
  end
end
