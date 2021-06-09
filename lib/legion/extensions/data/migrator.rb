require 'sequel/extensions/migration'

module Legion
  module Extensions
    module Data
      class Migrator < Sequel::IntegerMigrator
        def initialize(path, extension, _lex_name, **)
          Legion::Logging.fatal @extension
          @path = path
          @extension = extension
          super(Legion::Data::Connection.sequel, path)
        end

        def default_schema_column
          :schema_version
        end

        def default_schema_table
          :extensions
        end

        def schema_dataset
          dataset = Legion::Data::Connection.sequel.from(default_schema_table).where(namespace: @extension)
          return dataset unless dataset.count.positive?

          Legion::Logging.unknown Legion::Data::Model::Extension.insert(active: 1, namespace: @extension, extension: lex_name)
          Legion::Data::Connection.sequel.from(default_schema_table).where(namespace: @extension)
        end
        alias ds schema_dataset
      end
    end
  end
end
