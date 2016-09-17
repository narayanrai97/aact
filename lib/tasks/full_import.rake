namespace :import do
  namespace :full do
    task :run, [:force] => :environment do |t, args|
      begin
        if [1,4,8,12,16,22,26,30].include? Date.today.day || args[:force]
          load_event = ClinicalTrials::LoadEvent.create( event_type: 'full_import')
          all_tables = ActiveRecord::Base.connection.tables

          blacklist = %w(
            schema_migrations
            load_events
            sanity_checks
            statistics
            study_xml_records
          )

          tables_to_truncate = all_tables.reject do |table|
            blacklist.include?(table)
          end

          tables_to_truncate.each do |table|
            ActiveRecord::Base.connection.truncate(table)
          end

          client = ClinicalTrials::Client.new
          client.download_xml_files
          client.populate_studies

          load_event.update(new_studies: Study.count, changed_studies: 0)
          load_event.complete

          SanityCheck.run
          StudyValidator.new.validate_studies
          LoadMailer.send_notifications(load_event, client.errors)
        else
          puts "Not the first of the month - not running full import"
        end
      rescue StandardError => e
        updater.errors << {:name => 'An error was raised during the load.', :first_backtrace_line => e}
        LoadMailer.send_notifications(load_event, updater.errors)
        raise e
      end
    end
  end
end
