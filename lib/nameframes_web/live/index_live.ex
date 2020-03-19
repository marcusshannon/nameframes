defmodule NameframesWeb.IndexLive do
  use Phoenix.LiveView

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.PageView, "welcome.html", assigns)
  end

  def mount(_assigns, socket) do
    {:ok, socket}
  end
end
