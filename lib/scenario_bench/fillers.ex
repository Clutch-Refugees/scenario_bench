defmodule ScenarioBench.Fillers do
  use Hound.Helpers

  #TODO this is fictional

  def fill(:text, elementId, value, meta) do
    fill_field(elementId, value)
  end


  def fill(:select, elementId, value, meta) do
    options = find_all_within_element(elementId, :tag, "option")
    value = Regex.escape("#{value}")
    checked_out_elements = Enum.take_while options, fn(option)->
      option_value = attribute_value(option, "value")
      cond do
        Regex.match?(~r/#{value}/i, option_value) ->
          click option
          false
        Regex.match?(~r/#{value}/i, visible_text(option)) ->
          click option
          false
        true -> true
      end
    end

    if length(checked_out_elements) == length(options) do
      raise "Could not select option: #{value}"
    end
  end


  def fill(type, elementId, value, meta) do
    raise "No filler defined for #{type}"
  end

end
