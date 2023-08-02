defmodule WeatherStation.Linear do
  def find_slope({x1, y1}, {x2, y2}) do
    (y2 - y1) / (x2 - x1)
  end

  def find_b({x1, y1}, m) do
    m * -x1 + y1
  end

  def calculate_y_from_slope(x, m, b) do
    m * x + b
  end

  def calculate_x_from_slope(y, m, b) do
    (y - b) / m
  end

  def calculate_x_from_triangle(opposite, hypotenuse, x_offset, percentage) do
    calculate_x_from_triangle(opposite * percentage, hypotenuse * percentage, x_offset)
  end

  def calculate_x_from_triangle(opposite, hypotenuse, x_offset) do
    :math.sqrt(:math.pow(hypotenuse, 2) - :math.pow(opposite, 2)) + x_offset
  end

  def calculate_point_on_line({x1, y1}, {x2, y2}, percentage) do
    remainder = 1 - percentage
    {x1 * remainder + x2 * percentage, y1 * remainder + y2 * percentage}
  end

  def length({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  def sides({x1, y1}, {x2, y2}) do
    [abs(y1 - y2), abs(x1 - x2)]
  end

  def angle(p1, p2) do
    [opposite, _adjacent] = sides(p1, p2)
    hypotenuse = length(p1, p2)

    :math.asin(opposite / hypotenuse) * 180 / :math.pi()
  end
end
