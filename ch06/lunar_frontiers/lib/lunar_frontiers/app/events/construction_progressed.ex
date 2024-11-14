# ---
# Excerpted from "Real-World Event Sourcing",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/khpes for more book information.
# ---
defmodule LunarFrontiers.App.Events.ConstructionProgressed do
  @derive Jason.Encoder
  defstruct [:site_id, :site_type, :game_id, :location, :completed_ticks, :required_ticks, :tick]
end
