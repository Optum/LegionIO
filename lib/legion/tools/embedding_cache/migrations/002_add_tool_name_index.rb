# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:tool_embedding_cache) do
      add_index :tool_name, name: :idx_tool_embedding_cache_tool_name
    end
  end

  down do
    alter_table(:tool_embedding_cache) do
      drop_index :tool_name, name: :idx_tool_embedding_cache_tool_name
    end
  end
end
