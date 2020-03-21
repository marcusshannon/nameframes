defmodule NameframesWeb.Plugs.Fingerprint do
  use NameframesWeb, :controller

  def init(default) do
    default
  end

  def call(conn, _) do
    case get_session(conn, :fingerprint) do
      nil ->
        conn
        |> put_session(:fingerprint, Ecto.UUID.generate())
        |> redirect(to: "/")
        |> halt()

      fingerprint ->
        conn
        |> assign(:fingerprint, fingerprint)
    end
  end
end
