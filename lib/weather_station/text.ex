defmodule WeatherStation.Text do
  def t(:temperature_decimal, {nil, _unit}), do: ""
  def t(:temperature_symbol, nil), do: ""

  def t(_name, nil), do: "-"
  def t(_name, {nil, _}), do: "-"

  def t(:unit, unit), do: Atom.to_string(unit)

  def t(:average_wind_direction, degrees) do
    degrees = Kernel.trunc(degrees || 0)
    direction = Math.degrees_to_compass(degrees)

    "#{direction} #{degrees}°"
  end

  def t(:temperature, {c, unit}), do: "#{Math.c_to(c, unit) |> Float.floor(1)}"
  def t(:temperature_int, {c, unit}), do: "#{Math.c_to(c, unit) |> Kernel.trunc()}."

  def t(:temperature_decimal, {c, unit}), do: "#{Kernel.trunc(Math.c_to(c, unit) * 10) |> rem(10) |> abs()}"

  def t(:temperature_symbol, _c), do: "°"

  def t(:average_wind_speed, {mps, unit}) do
    "#{Math.mps_to(mps, unit)}"
  end

  def t(:rapid_wind_speed, {mps, unit}) do
    speed = Math.mps_to(mps, unit)

    String.pad_trailing("Gust: #{speed}", 9)
  end
end
