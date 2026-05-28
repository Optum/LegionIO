# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:tbi_patterns) do
      add_index :pattern_type, name: :idx_tbi_patterns_type
      add_index :tier, name: :idx_tbi_patterns_tier
    end
  end

  down do
    alter_table(:tbi_patterns) do
      drop_index :tier, name: :idx_tbi_patterns_tier
      drop_index :pattern_type, name: :idx_tbi_patterns_type
    end
  end
end
