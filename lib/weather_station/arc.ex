defmodule WeatherStation.Arc do
  @pi :math.pi()

  def calculate_point({cx, cy}, degrees, radius) do
    radians = degrees * (@pi / 180)
    x = cx + radius * :math.cos(radians)
    y = cy + radius * :math.sin(radians)
    {x, y}
  end

  def length(degrees, radius) do
    2 * @pi * radius * (degrees / 360)
  end
end
