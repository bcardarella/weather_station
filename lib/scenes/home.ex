defmodule WeatherStation.Scene.Home do
  use Scenic.Scene
  require Logger

  use Animate, get: &Scenic.Scene.get/3, assign: &Scenic.Scene.assign/3

  alias Scenic.Graph
  alias Scenic.Script
  alias WeatherStation.{Arc, Linear}

  import Scenic.Primitives
  import WeatherStation.Text


  @overlay_timeout 30_000
  # @seconds_in_day 60 * 60 * 24

  @active_graph_key :__active_graph__

  @font_name :roboto
  @font_metrics Scenic.Assets.Static.meta(@font_name) |> elem(1) |> elem(1)
  # @arial_font_metrics Scenic.Assets.Static.meta(:arial) |> elem(1) |> elem(1)

  @graph Graph.build(font: @font_name) |> rect({800, 600}, fill: {10, 11, 35})
  @large 50
  @medium 30
  @small 15

  @glow {85, 236, 241}
  @radius 80

  def init(scene, _param, _opts) do
    Scenic.PubSub.subscribe(:home)

    scene =
      scene
      |> Scenic.Scene.assign(
        rapid_wind_speed: 0,
        rapid_wind_direction: 0,
        average_wind_speed: 0,
        average_wind_direction: 0,
        temperature: 0,
        humidity: 0,
        speed_unit: :mph,
        temperature_unit: :f,
        humidity_unit: :mb,
        compass_scale: 1,
        temperature_scale: 1,
        barometer_scale: 1,
        daily_temperature_high: nil,
        daily_temperature_low: nil,
        daily_rapid_high: 0,
        daily_rapid_low: 0,
        overlay: reset_timer(nil),
        current_click: nil
      )
      |> render()

    {:ok, scene}
  end

  def render(scene) do
    data = Map.put(scene.assigns, :radius, @radius)

    # script =
    #   Script.start()
    #   |> Script.rectangle()
    #   |> Animate.script(fn(script, assigns) ->
    #     :ok
    #   end)

    graph =
      scene
      |> get_active_graph()
      |> temperature(data, translate: {300, 200})
      |> compass(data, translate: {500, 200})
      |> barometer(data, translate: {300, 400})
      |> overlay(data.overlay)

    Scenic.Scene.push_graph(scene, graph)
  end

  defp get_active_graph(scene, default_graph \\ @graph) do
    Scenic.Scene.get(scene, @active_graph_key, default_graph)
  end

  def arrow(graph, nil, radius, opts), do: arrow(graph, 0, radius, opts)
  def arrow(graph, degrees, radius, opts) do
    path(graph, [:begin, {:move_to, -10, -15}, {:line_to, 0, 15}, {:line_to, 10, -15}, {:line_to, 0, -10}, {:line_to, -10, -15}, :close_path], Keyword.merge(opts, radius: radius))
    |> Graph.modify(opts[:id], &move_arrow(&1, degrees))
  end

  defp move_arrow(arrow, degrees) do
    opts = Map.get(arrow, :opts, %{})
    radius = Keyword.get(opts, :radius, 0)
    radians = Math.degrees_to_radians(degrees)
    degrees = Math.rotate_degrees_for_compass(degrees)

    Scenic.Primitive.merge_opts(arrow, translate: Arc.calculate_point({0, 0}, degrees, radius), rotate: radians)
  end

  defp compass(graph, data, opts) do
    graph
    |> group(fn(g) ->
        g
        |> circle(data.radius, stroke: {2, @glow}, input: :cursor_button, id: :compass_circle)
        |> compass_ticks({data.radius * 0.95, 2 * :math.pi(), 0.06, 360 / 72}, stroke: {1, @glow})
        |> text(t(:average_wind_direction, data.average_wind_direction), fill: @glow, id: :wind_direction, text_align: :center, font_size: @small, translate: {0, -40})
        |> text(t(:average_wind_speed, {data.average_wind_speed, data.speed_unit}), id: :wind_speed, text_align: :center, font_size: @large, translate: {0, 10})
        |> text(t(:rapid_wind_speed, {data.rapid_wind_speed, data.speed_unit}), id: :rapid_wind_speed, text_align: :center, font_size: @small, translate: {0, 37})
        |> text(t(:unit, data.speed_unit), id: :speed_unit, text_align: :center, font_size: @small, translate: {0, 55})
        |> arrow(data.average_wind_direction, data.radius, stroke: {2, @glow}, fill: @glow, scale: 0.75, id: :wind_arrow)
        |> arrow(data.rapid_wind_direction, data.radius, stroke: {3, {9, 60, 180}}, id: :rapid_wind_arrow, scale: 1.15)
      end, Keyword.merge([id: :compass_gauge, scale: data.compass_scale], opts))
  end

  defp temperature(graph, data, opts) do
    circle_color = calculate_color(data.temperature)

    temperature_int = t(:temperature_int, {data.temperature, data.temperature_unit})
    temperature_decimal = t(:temperature_decimal, {data.temperature, data.temperature_unit})
    temperature_int_width = FontMetrics.width(temperature_int, @large, @font_metrics)
    temperature_decimal_width = FontMetrics.width(temperature_decimal, @medium, @font_metrics)

    # temperature_arrow = text("↑", font: :roboto)
    # temperature_daily_high = "#{t(:temperature, {data.daily_temperature_high, data.temperature_unit})}#{t(:temperature_symbol, nil)}"
    # arrow_width = FontMetrics.width(temperature_arrow, @small, )

    total_width = temperature_int_width + temperature_decimal_width
    int_offset = temperature_int_width - total_width / 2
    decimal_offset = total_width / 2 - temperature_decimal_width

    graph
    |> group(fn(g) ->
      g
      |> circle(data.radius, stroke: {10, circle_color}, input: :cursor_button, id: :temperature_circle)
      # |> text("↑")
      |> text("↑ #{t(:temperature, {data.daily_temperature_high, data.temperature_unit})}#{t(:temperature_symbol, data.daily_temperature_high)}", id: :daily_temperature_high, text_align: :center, translate: {0, -45}, font_size: @small)
      |> group(fn(g) ->
        g
        |> text(temperature_int, id: :current_temperature_int, font_size: @large, text_align: :right, translate: {int_offset, 0})
        |> text(temperature_decimal, id: :current_temperature_decimal, text_align: :left, translate: {decimal_offset, 0}, font_size: @medium)
        |> text(t(:temperature_symbol, data.temperature), id: :temperature_symbol, text_align: :left, font_size: 35, translate: {decimal_offset + 2, -8})
      end, translate: {0, 10})
      |> text("↓ #{t(:temperature, {data.daily_temperature_low, data.temperature_unit})}#{t(:temperature_symbol, data.daily_temperature_low)}", id: :daily_temperature_low, text_align: :center, translate: {0, 40}, font_size: @small)
      |> text(t(:unit, data.temperature_unit), id: :temperature_unit, text_align: :center, font_size: @small, translate: {0, 65})
    end, Keyword.merge([id: :temperature_gauge, scale: data.temperature_scale], opts))
  end

  def barometer(graph, data, opts) do
    barometer_arc = 4 * :math.pi() / 3
    barometer_rotate = 5 * :math.pi() / 6

    graph
    |> group(fn(g) ->
      g
      # |> arc({data.radius, 7 * :math.pi() / 6}, stroke: {2, @glow}, rotate: 13 * :math.pi() / 12, input: :cursor_button, id: :barometer_arc)
      |> arc({data.radius, barometer_arc}, stroke: {2, @glow}, rotate: barometer_rotate, input: :cursor_button, id: :barometer_arc)
      |> compass_ticks({data.radius * 0.95, barometer_arc, 0.06, 6}, rotate: barometer_rotate, stroke: {1, @glow})
      |> text(t(:unit, data.humidity_unit), id: :humidity_unit, text_align: :center, font_size: @small, translate: {0, 65})

    end, Keyword.merge([id: :barometer_gauge, scale: data.barometer_scale], opts))
  end

  def overlay(graph, nil), do:
    rect(graph, {800, 600}, input: [:cursor_button, :cursor_pos], fill: {10, 11, 35, 0x64}, id: :overlay)
  def overlay(graph, _ref), do: graph

  defp compass_ticks(graph, {radius, finish, length, angle_step}, opts) do
    origin = {0, 0}

    degrees = Math.radians_to_degrees(finish)

    ticks =
      %Easing.Range{first: 0, last: degrees, step: angle_step}
      |> Enum.map(fn angle ->
        p2 = Arc.calculate_point(origin, angle, radius)
        p1 = Linear.calculate_point_on_line(origin, p2, 1 - length)

        line_spec({p1, p2}, Keyword.merge(opts, pin: {0, 0}, stroke: {1, @glow}, id: :compass_tick))
      end)

    add_specs_to_graph(graph, ticks)
  end

  def handle_input({_, _}, :overlay, scene) do
    data = scene.assigns

    ref = reset_timer(data.overlay)
    scene =
      scene
      |> Scenic.Scene.assign(:overlay, ref)
      |> render()

    {:noreply, scene}
  end

  def handle_input({:cursor_button, {:btn_left, 1, _, _}}, context, scene) when context in [:compass_circle, :temperature_circle, :barometer_arc] do
    scale_name = lookup_gauge(context)

    scene =
      scene
      |> Scenic.Scene.assign(scale_name, 0.95)
      |> Scenic.Scene.assign(:current_click, {context, :down})
      |> render()

    {:noreply, scene}
  end

  def handle_input({:cursor_button, {:btn_left, 0, _, _}}, context, scene) when context in [:compass_circle, :temperature_circle, :barometer_arc] do
    data = scene.assigns

    scene = case data.current_click do
      {context, :down} ->
        scale_name = lookup_gauge(context)
        scene = Scenic.Scene.assign(scene, scale_name, 1)
        unit_name = lookup_unit_name(context)
        unit = Scenic.Scene.get(scene, unit_name) |> cycle_unit()
        Scenic.Scene.assign(scene, unit_name, unit)
      _ -> scene
    end

    scene =
      scene
      |> Scenic.Scene.assign(:currnt_click, nil)
      |> render()

    {:noreply, scene}
  end

  def handle_input(_event, _context, scene) do
    {:noreply, scene}
  end

  defp reset_timer(nil), do: Process.send_after(self(), :overlay, @overlay_timeout)
  defp reset_timer(ref), do: Process.cancel_timer(ref)

  defp lookup_gauge(:compass_circle), do: :compass_scale
  defp lookup_gauge(:temperature_circle), do: :temperature_scale
  defp lookup_gauge(:barometer_arc), do: :barometer_scale


  defp lookup_unit_name(:compass_circle), do: :speed_unit
  defp lookup_unit_name(:temperature_circle), do: :temperature_unit
  defp lookup_unit_name(:barometer_arc), do: :humidity_unit

  defp cycle_unit(:mph), do: :knts
  defp cycle_unit(:knts), do: :kph
  defp cycle_unit(:kph), do: :mph

  defp cycle_unit(:f), do: :c
  defp cycle_unit(:c), do: :f

  defp cycle_unit(:mb), do: :hg
  defp cycle_unit(:hg), do: :mb

  def calculate_color(nil), do: @glow
  def calculate_color(color) when is_tuple(color), do: color
  def calculate_color(temperature) when is_number(temperature) do
    low = {:color_hsv, {240, 100, 100}}
    high = {:color_hsv, {0, 100, 100}}

    Animate.Frame.calculate(:color, low, high, (temperature + 40) / 100)
  end

  def handle_info( {{Scenic.PubSub, :data}, {:home, %{"obs_st" => %{"wind_average" => speed, "wind_direction" => direction, "air_temperature" => temperature, "relative_humidity" => humidity}}, _timestamp}}, scene) do
    data = scene.assigns

    scene =
      scene
      |> Animate.push(:temperature, temperature, 1_000, {:sine, :out})
      |> Animate.push(:average_wind_direction, {:circular, direction}, 1000, {:quartic, :out})
      |> Animate.push(:average_wind_speed, speed, 1000, {:sine, :out})
      |> animate_temps(data.daily_temperature_high, data.daily_temperature_low, temperature)

    {:noreply, scene}
  end

  def handle_info({{Scenic.PubSub, :data}, {:home, %{"rapid_wind" => %{"wind_speed" => speed, "wind_direction" => direction}}, _timestamp}}, scene) do
    scene =
      scene
      |> Animate.push(:rapid_wind_direction, {:circular, direction}, 1000, {:quartic, :out})
      |> Animate.push(:rapid_wind_speed, speed, 1000, {:sine, :out})

    {:noreply, scene}
  end

  def handle_info(:overlay, scene) do
    data = scene.assigns
    reset_timer(data.overlay)
    scene =
      scene
      |> Scenic.Scene.assign(:overlay, nil)
      |> render()

    {:noreply, scene}
  end

  def handle_info({{Scenic.PubSub, :data}, {:home, _data, _timestamp}}, scene) do
    {:noreply, scene}
  end

  defp animate_temps(scene, nil, nil, current), do: animate_temps(scene, current, current, current)
  defp animate_temps(scene, current, current, current) do
    scene
    |> Animate.push(:daily_temperature_high, current, 1000, {:sine, :out})
    |> Animate.push(:daily_temperature_low, current, 1000, {:sine, :out})
  end
  defp animate_temps(scene, current_daily_high, _current_daily_low, current) when current >= current_daily_high,
    do: Animate.push(scene, :daily_temperature_high, current, 1000, {:sine, :out})
  defp animate_temps(scene, _current_daily_high, current_daily_low, current) when current <= current_daily_low,
    do: Animate.push(scene, :daily_temperature_low, current, 1000, {:sine, :out})
  defp animate_temps(scene, _current_daily_high, _current_daily_low, _current), do: scene
end
