defmodule Maps do
  use HTTPotion.Base
  import ShortMaps

  def default_params, do: %{key: Application.get_env(:maps, :key)}

  defp process_url(url) do
    "https://maps.googleapis.com/maps/api/" <> url
  end

  defp process_request_headers(hdrs) do
    Enum.into(hdrs, ["Accept": "application/json", "Content-Type": "application/json"])
  end

  defp process_options(opts) do
    opts
    |> Keyword.update(:query, default_params(), &(Map.merge(default_params(), &1)))
  end

  defp process_response_body(raw) do
    case Poison.decode(raw) do
      {:ok, body} -> body
      {:error, raw} -> {:error, raw}
    end
  end

  defp process_request_body(body) do
    body
  end

  @spec geocode(binary) :: {float, float}
  @doc ~S"""
  {latitude, longitude} -> ~m(utc_offset time_zone_id time_zone zone_abbr)a
  Uses googe – requires env var GOOG_KEY to be set, and to have proper permissions
    enabled in the Google developer console

  ## Examples
      # New York (Times Square)
      iex> Maps.geocode("Times Square, New York City")
      {40.758895, -73.985131}
  """
  def geocode(address) do
    case Maps.get("geocode/json", [query: ~m(address)]) do
      %{body: %{"results" => [%{"geometry" => ~m(location)} | _]}} ->
        ~m(lat lng) = location
        {lat, lng}
      _other -> nil
    end
  end

  @spec fill_address(binary) :: %{}
  def fill_address(address) do
    case Maps.get("geocode/json", [query: ~m(address)]) do
      %{body: %{"results" =>
        [%{"address_components" => address_components,
          "geometry" => %{"location" => %{"lat" => lat, "lng" => lng}}} | _]}} ->

            [street_number, street, locality, region, country, postal_code]
              = Enum.map(
                ~w(street_number route locality administrative_area_level_1 country postal_code),
                &(extract_component_with_type(address_components, &1)))

            address_lines = ["#{street_number} #{street}"]
            location = %{"latitude" => lat, "longitude" => lng}
            ~m(address_lines locality region country postal_code location)

      _other -> nil
    end
  end

  defp extract_component_with_type(address_components, type) do
    result =
      address_components
      |> Enum.filter(fn %{"types" => types} -> Enum.member?(types, type) end)
      |> Enum.map(fn %{"long_name" => long_name} -> long_name end)
      |> List.first()

    result || ""
  end

  @spec time_zone_of({float, float}) :: map
  @doc ~S"""
  {latitude, longitude} -> ~m(utc_offset time_zone_id time_zone zone_abbr)a
  Uses googe – requires env var GOOG_KEY to be set, and to have proper permissions
    enabled in the Google developer console

  ## Examples
      # New York (Times Square)
      iex> Maps.time_zone_of({40.758895, -73.985131})
      %{time_zone: "Eastern Daylight Time", time_zone_id: "America/New_York",
        utc_offset: -14400, zone_abbr: "EDT"}

      # Chicago (Second City)
      iex> Maps.time_zone_of({41.91152599999999, -87.635373})
      %{time_zone: "Central Daylight Time", time_zone_id: "America/Chicago",
        utc_offset: -18000, zone_abbr: "CDT"}

      # Colorado (University of Boulder)
      iex> Maps.time_zone_of({40.00758099999999, -105.2659417})
      %{time_zone: "Mountain Daylight Time", time_zone_id: "America/Denver",
        utc_offset: -21600, zone_abbr: "MDT"}

      # Arizona (Grand Canyon)
      iex> Maps.time_zone_of({36.1069652, -112.1129972})
      %{time_zone: "Mountain Standard Time", time_zone_id: "America/Phoenix",
        utc_offset: -25200, zone_abbr: "MST"}

      # San Francisco (Golden Gate Bridge)
      iex> Maps.time_zone_of({37.8190478, -122.4783932})
      %{time_zone: "Pacific Daylight Time", time_zone_id: "America/Los_Angeles",
        utc_offset: -25200, zone_abbr: "PDT"}

      # Alaska (Juneau)
      iex> Maps.time_zone_of({58.3019444, -134.4197221})
      %{time_zone: "Alaska Daylight Time", time_zone_id: "America/Anchorage",
        utc_offset: -28800, zone_abbr: "ADT"}

      # Hawaii (Honolulu)
      iex> Maps.time_zone_of({21.3069444, -157.8583333})
      %{time_zone: "Hawaii-Aleutian Standard Time", time_zone_id: "Pacific/Honolulu",
        utc_offset: -36000, zone_abbr: "HST"}
  """
  def time_zone_of({x, y}) do
    %{body: %{"dstOffset" => dst_offset, "rawOffset" => raw_offset,
      "timeZoneId" => time_zone_id, "timeZoneName" => time_zone}}
      = Maps.get(
          "timezone/json",
          [query: %{"location" => "#{x},#{y}", "timestamp" => DateTime.utc_now() |> DateTime.to_unix()}])

    zone_abbr = abbreviate_zone(time_zone)
    utc_offset = raw_offset + dst_offset
    ~m(utc_offset time_zone_id time_zone zone_abbr)a
  end

  def time_zone_of(address_string) do
    address_string
    |> geocode()
    |> time_zone_of()
  end


  @spec abbreviate_zone(binary) :: binary
  @doc ~S"""
  {latitude, longitude} -> ~a{utc_offset, time_zone_id, time_zone, zone_abbr}
  Uses googe – requires env var GOOG_KEY to be set, and to have proper permissions
    enabled in the Google developer console

  ## Examples
      iex> abbreviate_zone("Alaska Daylight Time")
      "ADT"
  """
  defp abbreviate_zone(time_zone) do
    time_zone
    |> String.split(" ")
    |> Enum.map(fn word -> String.slice(word, 0..0) end)
    |> Enum.join("")
  end
end
