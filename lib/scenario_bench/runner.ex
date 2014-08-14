defmodule ScenarioBench.Runner do

  def run(scenario, data, options) do
    run(scenario, data, scenario, options, [])
  end


  def run(_scenario, _data, [], _options, _tree) do
  end


  def run(scenario, data, [field | fields], options, tree) do
    node_path = tree ++ [field[:name]]
    case is_list(field[:type]) do
      true ->
        fill_group node_path, data, options, node_path
      false ->
        fill_field field, data, options, node_path
    end

    run(scenario, data, fields, options, tree)
  end


  defp fill_group(scenario, data, options, node_path) do
    field = get_in scenario, node_path
    parent_node  = Enum.slice node_path, 0, length(node_path) - 1
    current_leaf = List.last(node_path)
    case get_value_of(node_path, data) do
      nil -> true
      values when is_list(values) ->
        Enum.with_index(values)
        |> Enum.each(fn({_item, index})->
             new_node_path = parent_node ++ {current_leaf, index}
             run(scenario, data, field[:type], options, new_node_path)
           end)
      _anything ->
        raise "Expected value for #{field[:name]} to be a list"
    end
  end


  defp fill_field(field, data, _options, node_path) do
    field_info = %{ node: node_path }
    case get_value_of(node_path, data) do
      nil   -> true
        IO.inspect "SKIP: #{field[:name]}"
      value ->
        IO.inspect "FILL: #{field[:name]} with #{value}"
    end
  end


  def get_value_of([], data), do: data
  def get_value_of(fields, nil), do: nil


  def get_value_of([path_item | path_items], data) when is_tuple(path_item) do
    {leaf_name, index} = path_item
    case get_in(data, [leaf_name]) do
      nil ->
        node_data_of_index = nil
      node_data ->
        node_data_of_index = Enum.fetch!(node_data, index)
    end
    get_value_of(path_items, node_data_of_index)
  end


  def get_value_of([path_item | path_items], data) do
    node_data = get_in(data, [path_item])
    get_value_of(path_items, node_data)
  end
end
