require 'albacore/albacoretask'

# Generate commands for the SQL Compare 10 command line utility
# Not all SQL Compare options are supported - primarily intended for use in build scripts, 
# updating a database from a set of SQL Compare schema scripts

class SQLCompare
  include Albacore::Task
  include Albacore::RunCommand

  attr_accessor :sync
  attr_accessor :target_server, :target_db, :target_username, :target_password, :script_path
  attr_accessor :server, :database, :username, :password

  def initialize
    @sync = true #Enable sync by default
    super()
    config = Albacore.configuration.sqlcompare.to_hash
    update_attributes config
    @target_db ||= @database
  end

  def execute
    # If we don't have a command set already, try to use a default SQL Compare 10 install location
    @command ||= set_command_to_default
    fail_with_message 'SQLCompare failed. SQL Compare not installed or command path not set.' if @command.nil?

    result = run_command "SQLCompare", param_list

    fail_with_message 'SQLCompare failed.' unless result
  end

  # Sets @command to the default install location for SQL Compare 10 (x86 or 64bit), if one exists
  def set_command_to_default

    @command = ['Program Files', 'Program Files (x86)'].
      map { |p| File.join(ENV['SystemDrive'],p,'Red Gate','SQL Compare 10','SQLCompare.exe') }.
      select { |f| File.exist?(f) }.
      first

  end
  
  # Create a parameter using the /param:value format used by SQL Compare
  def build_parameter(switch, val)
    "/#{switch}:#{val}"
  end

  # Add tSQLt exclusion statements
  def exclude_tsqlt
    @parameters.concat %w'/Exclude:storedprocedure:tSQLt.* /Exclude:storedprocedure:test.* /Exclude:function:tSQLt.*
    /Exclude:assembly:tSQLtCLR /Exclude:schema:tSQLt /Exclude:schema:test.* /Exclude:view:tSQLt.* /Exclude:userdefinedtype:tSQLt.*
    /Exclude:table:tSQLt.*'
  end

  # Use attributes to build a SQL Compare parameter list
  def param_list
    params = []

    params << build_parameter('scripts1', @script_path) if @script_path
    params << build_parameter('server2', @target_server) if @target_server
    params << build_parameter('server2', @server) if @server
    params << build_parameter('username2', @target_username) if @target_username
    params << build_parameter('username2', @username) if @username
    params << build_parameter('password2', @target_password) if @target_password
    params << build_parameter('password2', @password) if @password
    params << build_parameter('database2', @target_db) if @target_db
    params << build_parameter('database2', @database) if @database
    params << '/sync' if @sync

    params.join(' ')
  end
end
