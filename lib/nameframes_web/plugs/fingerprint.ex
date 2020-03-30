defmodule NameframesWeb.Plugs.Fingerprint do
  use NameframesWeb, :controller

  def init(default) do
    default
  end

  def call(conn, _) do
    case get_session(conn, :fingerprint) do
      nil ->
        fingerprint = Ecto.UUID.generate()

        conn
        |> put_session(:fingerprint, fingerprint)
        |> assign(:fingerprint, fingerprint)

      fingerprint ->
        conn
        |> assign(:fingerprint, fingerprint)
    end
  end
end
