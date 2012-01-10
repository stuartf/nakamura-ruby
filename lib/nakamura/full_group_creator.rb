#!/usr/bin/env ruby

# work on KERN-1881 to duplicate all 11 to 13 POSTs that go into creating a group

require 'json'
require 'nakamura'
require 'nakamura/users'
require 'nakamura/file'
include SlingInterface
include SlingUsers
include SlingFile

$FULL_GROUP_URI="system/world/create"
$BATCH_URI = "system/batch"

module SlingUsers

  # a subclass of the library UserManager for creating fully featured groups
  # unlike the skeleton groups that super.create_group creates
  class FullGroupCreator < UserManager
    attr_reader :log, :file_log

    def initialize(sling, file_log = nil)
      @sling = sling
      super sling
      @file_log = file_log
    end

    # this method follows the series of POSTs that the UI makes to create a group with a
    # full set of features including the initial sakai docs for Library and Participants
    def create_full_group(creator_id, groupname, title = '', description = '')
      creator = User.new(creator_id, "testuser")
      @sling.switch_user(creator)

      group = Group.new(groupname)

      params = {"data" => JSON.generate({
        "id" => groupname,
        "title" => title,
        "description" => description,
        "joinability" => "yes",
        "visibility" => "public",
        "tags" => ["test-tag1", "test-tag2"],
        "worldTemplate" => "/var/templates/worlds/group/simple-group",
        "_charset_" => "utf-8",
        "usersToAdd" => [{
          "userid" => creator_id,
          "name" => creator.name,
          "firstname" => creator.firstName,
          "role" => "manager",
          "roleString" => "Manager",
          "creator" => "true"
        }]
      })}

      result = @sling.execute_post(@sling.url_for($GROUP_WORLD_URI), params)
      if (result.code.to_i > 299)
        @log.error result.body
        return nil
      end

      # return the group that was created in create_target_group
      return group
    end
  end

  if ($PROGRAM_NAME.include? 'full_group_creator.rb')
    @sling = Sling.new("http://localhost:8080/", false)
    @sling.log.level = Logger::DEBUG
    fgc = SlingUsers::FullGroupCreator.new @sling
    fgc.log.level = Logger::DEBUG
    fgc.file_log.level = Logger::DEBUG if (@file_log)
    fgc.create_full_group "bp7742", "test-1881-group8", "test-1881-group8 Title", "test-1881-group8 Description"
  end
end
