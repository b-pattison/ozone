class HomeController < ApplicationController
  def index
    require 'net/http'
    require 'json'
    
    @zip_code = params[:zip_code].to_s.strip
    @zip_code = (@zip_code =~ /^\d{5}$/) ? @zip_code : "97003"

    @url = "https://www.airnowapi.org/aq/observation/zipCode/current/?format=application/json&zipCode=#{@zip_code}&distance=25&API_KEY=D49D538C-1E72-4B0A-BF39-656C2CD84A4D"
    @uri = URI(@url)
    @response = Net::HTTP.get(@uri)
    @output = JSON.parse(@response)
    # If the API returns an empty array (e.g., invalid ZIP), default to gray
    if @output.is_a?(Array) && @output.empty?
      @api_color = "gray"
      @current_ozone_status = "No data available."
      @error_message = "Invalid ZIP code. Please enter a valid 5-digit ZIP code."
      return
    end

    if @output.is_a?(Array)
      @current_ozone_status = @output.first.dig("Category", "Name")
      @output.each do |pair|
        pair.each do |key, value|
          variable_name = "@current_ozone_#{key.downcase}"
          instance_variable_set(variable_name, value.nil? ? "No data available" : value)
          end
        end
      @api_color = aqi_color_for(@current_ozone_aqi)
    else
      # Non-array response (e.g., API error payload)
      @api_color = "gray"
    end
  end

  private

  def aqi_color_for(value)
    return "gray" if value.nil? || value == "No data available"
    v = value.to_i
    return "gray" if v <= 0
    case v
    when 1..50 then "green"
    when 51..100 then "yellow"
    when 101..150 then "orange"
    when 151..200 then "red"
    when 201..300 then "purple"
    else "maroon"
    end
  end
end
