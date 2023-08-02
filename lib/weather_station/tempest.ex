defmodule WeatherStation.Tempest do
  use GenServer

  @type_to_key %{
    "evt_precip" => "evt",
    "evt_strike" => "evt",
    "rapid_wind" => "ob",
    "obs_air" => "obs",
    "obs_sky" => "obs",
    "obs_st" => "obs",
    "device_status" => "sensor_status",
    "hub_status" => "reset_flags"
  }

  def start_link([args]) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(:ok) do
    Scenic.PubSub.register(:home)

    # sim()

    :gen_udp.open(50222, [:binary, broadcast: true, active: true])

    {:ok, %{}}
  end

  def sim() do
    sim_wind()
    sim_rapid()
  end

  defp sim_wind() do
    temperature = Float.floor(:rand.uniform() * 100) - 40
    direction = Kernel.trunc(:rand.uniform() * 360)
    humidity = Kernel.trunc(:rand.uniform() * 1300)
    speed = Float.floor(:rand.uniform() * 20)

    Process.send_after(self(), {:sim, %{"obs_st" => %{"wind_direction" => direction, "wind_average" => speed, "air_temperature" => temperature, "relative_humidity" => humidity}}}, 2_100)
  end

  defp sim_rapid() do
    direction = Kernel.trunc(:rand.uniform() * 360)
    speed = Float.floor(:rand.uniform() * 20)

    Process.send_after(self(), {:sim, %{"rapid_wind" => %{"wind_direction" => direction, "wind_speed" => speed}}}, 3_000)
  end

  def handle_info({:sim, data}, socket) do
    Scenic.PubSub.publish(:home, data)

    Map.keys(data)
    |> List.first()
    |> case do
      "rapid_wind" -> sim_rapid()
      "obs_st" -> sim_wind()
    end

    {:noreply, socket}
  end

  def handle_info({:udp, _socket, _addr, _port, payload}, socket) do
    obs =
      payload
      |> Jason.decode!()
      |> extract_observation_data()

    Scenic.PubSub.publish(:home, obs)

    {:noreply, socket}
  end

  def handle_info({:try, obs}, socket) do
    Scenic.PubSub.publish(:home, obs)
    {:noreply, socket}
  end

  defp extract_observation_data(payload) do
    type = payload["type"]
    key = @type_to_key[type]

    new_data = parse_type_data(type, payload[key])

    %{type => new_data}
  end

  defp extract_radio_stats(payload, current_radio_stats) do
    new_radio_stats =
      payload["radio_stats"]
      |> parse_radio_stats()

    %{"radio_stats" => Map.merge(current_radio_stats, new_radio_stats)}
  end

  defp parse_type_data("evt_precip", evt) do
    %{"time_epoch" => evt}
  end

  defp parse_type_data("evt_strike", [time_epoch, distance, energy]) do
    %{
      "time_epoch" => time_epoch,
      "distance" => distance,
      "energy" => energy
    }
  end

  defp parse_type_data("rapid_wind", [time_epoch, wind_speed, wind_direction]) do
    %{
      "time_epoch" => time_epoch,
      "wind_speed" => wind_speed,
      "wind_direction" => wind_direction
    }
  end

  defp parse_type_data("obs_air", [[time_epoch, station_pressure, air_temperature, relative_humidity, lightning_strike_count, lightning_strike_average_distance, battery, report_interval]]) do
    %{
      "time_epoch" => time_epoch,
      "station_pressure" => station_pressure,
      "air_temperature" => air_temperature,
      "relative_humidity" => relative_humidity,
      "lightning_strike_count" => lightning_strike_count,
      "lightning_strike_average_distace" => lightning_strike_average_distance,
      "battery" => battery,
      "report_interval" => report_interval
    }
  end

  defp parse_type_data("obs_sky", [[time_epoch, illuminence, uv, rain_amount_over_previous_minute, wind_lull, wind_average, wind_gust, wind_direction, battery, report_interval, solar_radiation, local_delay_rain_accumulation, precipitation_type_value, wind_sample_interval]]) do
    precipitation_type =
      case precipitation_type_value do
        0 -> "none"
        1 -> "rain"
        2 -> "hail"
      end

    %{
      "time_epoch" => time_epoch,
      "illuminence" => illuminence,
      "uv" => uv,
      "rain_amount_over_previous_minute" => rain_amount_over_previous_minute,
      "wind_lull" => wind_lull,
      "wind_average" => wind_average,
      "wind_gust" => wind_gust,
      "wind_direction" => wind_direction,
      "battery" => battery,
      "report_interval" => report_interval,
      "solar_radiation" => solar_radiation,
      "local_delay_rain_accumulation" => local_delay_rain_accumulation,
      "precipitation_type" => precipitation_type,
      "wind_sample_interval" => wind_sample_interval
    }
  end

  defp parse_type_data("obs_st", [[time_epoch, wind_lull, wind_average, wind_gust, wind_direction, wind_sample_interval, station_pressure, air_temperature, relative_humidity, illuminence, uv, solar_radiation, rain_amount_over_previous_minute, precipitation_type_value, lightning_strike_average_distance, lightning_strike_count, battery, report_interval]]) do
    precipitation_type =
      case precipitation_type_value do
        0 -> "none"
        1 -> "rain"
        2 -> "hail"
        3 -> "rain + hail"
      end

    %{
      "time_epoch" => time_epoch,
      "wind_lull" => wind_lull,
      "wind_average" => wind_average,
      "wind_gust" => wind_gust,
      "wind_direction" => wind_direction,
      "wind_sample_interval" => wind_sample_interval,
      "station_pressure" => station_pressure,
      "air_temperature" => air_temperature,
      "relative_humidity" => relative_humidity,
      "illuminence" => illuminence,
      "uv" => uv,
      "solar_radiation" => solar_radiation,
      "rain_amount_over_previous_minute" => rain_amount_over_previous_minute,
      "precipitation_type" => precipitation_type,
      "lightning_strike_average_distace" => lightning_strike_average_distance,
      "lightning_strike_count" => lightning_strike_count,
      "battery" => battery,
      "report_interval" => report_interval
    }
  end

  defp parse_type_data("device_status", sensor_status) do
    case sensor_status do
      0b000000000 -> "Sensors OK"
      0b000000001 -> "Lightning failed"
      0b000000010 -> "Lightning noise"
      0b000000100 -> "Lightning disturber"
      0b000001000 -> "Pressure failed"
      0b000010000 -> "Temperature filed"
      0b000100000 -> "RH failed"
      0b001000000 -> "Wind failed"
      0b010000000 -> "Precipitation failed"
      0b100000000 -> "Light/UV failed"
      0x00008000 -> "Power booster depleted"
      0x00010000 -> "Power booster shore power"
      _ -> nil
    end
  end

  defp parse_type_data("hub_status", reset_flags) do
    reset_flags
    |> String.split(",", trim: true)
    |> Enum.map(fn flag ->
      case flag do
        "BOR" -> "Brownout reset"
        "PIN" -> "Pin reset"
        "POR" -> "Power reset"
        "SFT" -> "Software reset"
        "WDG" -> "Watchdog reset"
        "WWD" -> "Window watchdog reset"
        "LPW" -> "Low-power reset"
        "HRDFLT" -> "Hard fault detected"
      end
    end)
  end

  defp parse_radio_stats(nil), do: %{}

  defp parse_radio_stats([version, reboot_count, bus_error_count, radio_status, radio_network_id]) do
    radio_status =
      case radio_status do
        0 -> "Radio off"
        1 -> "Radio on"
        3 -> "Radio active"
        7 -> "BLE Connected"
      end

    %{
      "version" => version,
      "reboot_count" => reboot_count,
      "bus_error_count" => bus_error_count,
      "radio_status" => radio_status,
      "radio_network_id" => radio_network_id
    }
  end
end
