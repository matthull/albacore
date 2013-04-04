require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module SQLCompare
    include Albacore::Configuration

    def sqlcompare
      @sqlcompareconfig ||= OpenStruct.new.extend(OpenStructToHash)
      yield(@sqlcompareconfig) if block_given?
      @sqlcompareconfig
    end
  end
end
