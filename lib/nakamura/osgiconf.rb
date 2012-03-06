#!/usr/bin/env ruby

require 'logger'

module OSGIConf

  class Conf

    attr_accessor :log

    def initialize(sling)
      @sling = sling
      @log = Logger.new(STDOUT)
      @log.level = Logger::WARN
    end

    def setProperties(factoryPid, props)
      path = "/system/console/configMgr/%5BTemporary%20PID%20replaced%20by%20real%20PID%20upon%20save%5D"
      props["propertylist"] = props.keys.join(",")
      props["apply"] = true
      props["action"] = "ajaxConfigManager"
      props["factoryPid"] = factoryPid
      res = @sling.execute_post(@sling.url_for(path), props)
      if ( res.code != "200" )
        @log.debug(res.body)
        @log.info(" Unable to update config for #{factoryPid}")
      end
      return res
    end
  end
end
