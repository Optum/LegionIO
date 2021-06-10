require_relative 'base'

module Legion
  module Extensions
    module Builder
      module Runners
        include Legion::Extensions::Builder::Base

        attr_reader :runners

        def build_runners
          @runners = {}
          lex_class.const_set('Runners', Module.new) unless lex_class.const_defined?('Runners')
          require_files(runner_files)
          build_runner_list
        end

        def build_runner_list
          runner_files.each do |file|
            runner_name = file.split('/').last.sub('.rb', '')
            runner_class =  "#{lex_class}::Runners::#{runner_name.split('_').collect(&:capitalize).join}"
            loaded_runner = Kernel.const_get(runner_class)

            @runners[runner_name.to_sym] = {
              extension:       lex_class.to_s.downcase,
              extension_name:  extension_name,
              extension_class: lex_class,
              runner_name:     runner_name,
              runner_class:    runner_class,
              runner_path:     file,
              class_methods:   {}
            }

            @runners[runner_name.to_sym][:scheduled_tasks] = loaded_runner.scheduled_tasks if loaded_runner.method_defined? :scheduled_tasks

            if settings.key?(:runners) && settings[:runners].key?(runner_name.to_sym)
              @runners[runner_name.to_sym][:desc] = settings[:runners][runner_name.to_sym][:desc]
            end

            loaded_runner.public_instance_methods(false).each do |runner_method|
              @runners[runner_name.to_sym][:class_methods][runner_method] = {
                args: loaded_runner.instance_method(runner_method).parameters
              }
            end

            loaded_runner.methods(false).each do |runner_method|
              next if %i[scheduled_tasks runner_description].include? runner_method

              @runners[runner_name.to_sym][:class_methods][runner_method] = {
                args: loaded_runner.method(runner_method).parameters
              }
            end
          end
        end

        def runner_files
          @runner_files ||= find_files('runners')
        end
      end
    end
  end
end
