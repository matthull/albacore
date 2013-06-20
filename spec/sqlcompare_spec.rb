require 'spec_helper'
require 'albacore/sqlcompare'

describe SQLCompare do

  let(:strio) { StringIO.new }

  let(:sqlcompare) do
    s = SQLCompare.new
    s.log_device = strio
    s.log_level = :verbose
    s
  end

  describe 'with defaults' do
    
    it 'has sync turned on' do
      sqlcompare.sync.should be_true
    end
  end


  describe "#build_parameter" do
    
    it "combines the arguments into a command line parameter" do
      sqlcompare.build_parameter('D', 'somearg').should == '/D:somearg'
    end
  end

  describe "#param_list" do
  
    it "generates a SQL Compare parameter list based on object attributes" do
      sqlcompare.target_username = 'admin'
      sqlcompare.target_password = 'banana'
      sqlcompare.target_db = 'MyData'

      sqlcompare.param_list.should include '/username2:admin /password2:banana /database2:MyData'

    end

    it "appends /sync if sync is turned on" do
      sqlcompare.sync = true
      
      sqlcompare.param_list.should include '/sync' 
    end

    it "omits /sync if sync is turned off" do
      sqlcompare.sync = false

      sqlcompare.param_list.should_not include '/sync'
    end
  end

  describe '#exclude_tsqlt' do
    before do
      sqlcompare.exclude_tsqlt
    end

    it "adds tsqlt exclusions to the parameter list" do
      sqlcompare.parameters.should include '/Exclude:storedprocedure:tSQLt.*'
    end
  end

  describe 'supress error on identical databases flag' do
    before do
      sqlcompare.suppress_error_on_identical_databases
    end

    it 'adds /include:identical to params' do
      sqlcompare.parameters.should include '/include:identical'
    end
  end

  describe '#execute' do

    context 'without a command path' do

      before do
        sqlcompare.extend(FailPatch)
        sqlcompare.stub(:set_command_to_default => nil)
        sqlcompare.execute
      end 

      it 'logs an error' do
        strio.string.should include 'not installed or command path not set.'
      end
    end


    context 'with a command path and parameters set' do
      before do
        sqlcompare.script_path = "project/scripts"
        sqlcompare.sync = true
        sqlcompare.command = 'c:\SQL Compare 10\SQLCompare.exe'
      end

      it "passes a parameter list to run_command" do

        sqlcompare.stub(:run_command).and_return('success')
        sqlcompare.should_receive(:run_command).with('SQLCompare',  %r(/scripts1:project/scripts.*/sync))
        sqlcompare.execute
      end
    end
  end

  describe 'with sqlcompare style config' do

    let(:sqlcompare) do
      Albacore.configure do |config|
        config.sqlcompare.target_server = 'MyServer'
        config.sqlcompare.target_db = 'MyDatabase'
        config.sqlcompare.target_username = 'Admin'
        config.sqlcompare.target_password = 'Secret'
        config.sqlcompare.script_path = 'scripts'
      end
      SQLCompare.new
    end

    it 'uses configured values' do
      sqlcompare.param_list.should include '/database2:MyDatabase'
      sqlcompare.param_list.should include '/server2:MyServer'
      sqlcompare.param_list.should include '/username2:Admin'
      sqlcompare.param_list.should include '/password2:Secret'
      sqlcompare.param_list.should include '/scripts1:scripts'
    end
  end

  describe 'with sqlcmd style config' do
    let(:sqlcompare) do 
      Albacore.configure do |config|
        config.sqlcompare.script_path = 'scripts'
        config.sqlcompare.server = 'SomeServer'
        config.sqlcompare.database = 'SomeDatabase'
        config.sqlcompare.username = 'User'
        config.sqlcompare.password = 'banana'
      end
      SQLCompare.new
    end

    it 'uses configured values' do
        sqlcompare.param_list.should include '/database2:SomeDatabase'
        sqlcompare.param_list.should include '/server2:SomeServer'
        sqlcompare.param_list.should include '/username2:User'
        sqlcompare.param_list.should include '/password2:banana'
        sqlcompare.param_list.should include '/scripts1:scripts'
    end
  end
end
