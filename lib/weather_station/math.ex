defmodule Math do
  def rotate_degrees_for_compass(nil), do: 270
  def rotate_degrees_for_compass(degrees) do
    cond do
      degrees < 90 -> 360 - (90 - degrees)
      true -> degrees - 90
    end
  end

  def degrees_to_radians(nil), do: degrees_to_radians(0)
  def degrees_to_radians(degrees), do: degrees * :math.pi() / 180

  def radians_to_degrees(nil), do: radians_to_degrees(0)
  def radians_to_degrees(radians), do: radians * 180 / :math.pi()

  def c_to(temperature, :c) when is_float(temperature), do: Float.round(temperature, 1)
  def c_to(temperature, :f) when is_float(temperature), do: Float.round(temperature * 1.8 + 32, 1)
  def c_to(_, _unit), do: 0.0

  def mps_to(mps, :mph) when is_float(mps), do: Float.round(mps * 2.236936, 1)
  def mps_to(mps, :knts) when is_float(mps), do: Float.round(mps * 1.9438445, 1)
  def mps_to(mps, :kph) when is_float(mps), do: Float.round(mps / 1000 * 60 * 60, 1)
  def mps_to(_, _units), do: ""

  def degrees_to_compass(degrees) do
    case degrees do
      d when d in 0..11 -> "N"
      d when d in 12..33 -> "NNE"
      d when d in 34..56 -> "NE"
      d when d in 57..78 -> "ENE"
      d when d in 79..101 -> "E"
      d when d in 102..123 -> "ESE"
      d when d in 124..146 -> "SE"
      d when d in 147..168 -> "SSE"
      d when d in 169..191 -> "S"
      d when d in 192..213 -> "SSW"
      d when d in 214..236 -> "SW"
      d when d in 237..258 -> "WSW"
      d when d in 259..281 -> "W"
      d when d in 282..303 -> "WNW"
      d when d in 304..326 -> "NW"
      d when d in 326..348 -> "NNW"
      d when d in 349..360 -> "N"
      _ -> ""
    end
  end
end
