defmodule ScenarioBench.Utils do
  def get_value_of([], data),    do: data
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
    node_data = case is_map(data) do
                  true  -> get_in(data, [path_item])
                  false -> data
                end
    get_value_of(path_items, node_data)
  end


  def make_extras(traversal_path, data) do
    %{
      field: get_field_name(List.last traversal_path),
      node:  get_node(traversal_path),
      data:  data
    }
  end


  def get_node(traversal_path) do
    Enum.reduce(traversal_path, [], fn(item, path_items)->
      path_items ++ [get_field_name(item)]
    end)
    |> Enum.join(".")
  end


  def get_field_name({field_name, _index}) do
    field_name
  end

  def get_field_name(field_name) do
    field_name
  end


  def similar_callback_action(action) do
    case action do
      :before  -> :before_each
      :after   -> :after_each
    end
  end
end
