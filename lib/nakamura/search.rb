#!/usr/bin/env ruby

module SlingSearch

  $SEARCH = "var/search/"

  class SearchManager

    def initialize(sling)
      @sling = sling
    end

    def create_search_template(name, language, template)
      return @sling.create_node("#{$SEARCH}#{name}", "sakai:query-language" => language, "sakai:query-template" => template, "sling:resourceType" => "sakai/search") 
    end

    def search_for_user(username)
      return json_search("users", "q" => username) 
    end

    def search_for_group(group)
      return json_search("groups", "q" => group) 
    end

    def search_for_site(sitepropertyvalue)
      return json_search("sites", "q" => sitepropertyvalue)
    end
    
    def search_for_file(query)
      return json_search('files/allfiles.json', 'q' => query)
    end

    private
    def json_search(template, params)
      url = @sling.url_for($SEARCH + template) + ".json?" + params.collect{|k,v| URI.escape(k) + "=" + URI.escape(v)}.join("&")
      return JSON.parse(@sling.execute_get(url).body)
    end
  end

end
