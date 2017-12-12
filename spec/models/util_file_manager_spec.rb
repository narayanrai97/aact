require 'rails_helper'

describe Util::FileManager do
  describe 'create static db copy' do
    it "should save db static copy to the appropriate directory" do
      stub_request(:get, "https://prsinfo.clinicaltrials.gov/definitions.html").
           with(headers: {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
           to_return(status: 200, body: "", headers: {})

      allow_any_instance_of(Util::FileManager).to receive(:make_file_from_website).and_return(Util::FileManager.schema_diagram)
      fm=Util::FileManager.new
      dm=Util::DbManager.new
      zip_file=dm.take_snapshot
      expect(File).to exist(zip_file)
      # Manager returns the dmp file from zip file content
      dump_file=fm.get_dump_file_from(zip_file)
      expect(dump_file.name).to eq('postgres_data.dmp')
      # The dump file contains commands to create the database"
      content=dump_file.get_input_stream.read
      expect(content).to include("CREATE DATABASE aact_back")
      expect(content.scan('DROP TABLE').size).to eq(42)
      expect(content.scan('CREATE TABLE').size).to eq(42)
      # If manager asked to get dmp file from the dmp file itself, it should simply return it
      dump_file2=fm.get_dump_file_from(dump_file)
      expect(dump_file.name).to eq('postgres_data.dmp')
    end
  end

end
