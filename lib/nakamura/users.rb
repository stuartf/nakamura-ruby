#!/usr/bin/env ruby

require 'digest/sha1'
require 'logger'

$USERMANAGER_URI="system/userManager/"
$GROUP_URI="#{$USERMANAGER_URI}group.create.html"
$GROUP_WORLD_URI="system/world/create"
$USER_URI="#{$USERMANAGER_URI}user.create.html"
$DEFAULT_PASSWORD="testuser"

module SlingUsers

  class Principal

    attr_accessor :name

    def initialize(name)
      @name = name
    end


    # Get the public path for a user
    def public_path_for(sling)
      return home_path_for(sling) + "/public"
    end

    # Get the private path for a user
    def private_path_for(sling)
      return home_path_for(sling) + "/private"
    end

    def message_path_for(sling,messageid,mailbox)
      #return home_path_for(sling) + "/message/"+messageid[0,2]+"/"+messageid[2,2]+"/"+messageid[4,2]+"/"+messageid[6,2]+"/"+messageid
      return home_path_for(sling) + "/message/#{mailbox}/#{messageid}"
    end

  end


  class Group < Principal
    def to_s
      return "Group: #{@name}"
    end

    def update_properties(sling, props)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"), props)
    end

    def add_member(sling, principal, type)
      principal_path = "/#{$USERMANAGER_URI}#{type}/#{principal}"
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":member" => principal_path })
    end

    def add_members(sling, principals)
      principal_paths = principals.collect do |principal|
        if principal.index("g-") == 0
          type = "group"
        else
          type = "user"
        end
        "/#{$USERMANAGER_URI}#{type}/#{principal}"
      end
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":member" => principal_paths })
    end

    def add_manager(sling, principal)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":manager" => principal })
    end

    def add_viewer(sling, principal)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":viewer" => principal })
    end

    def details(sling)
      return sling.get_node_props(group_url)
    end

    def remove_member(sling, principal, type)
      principal_path = "/#{$USERMANAGER_URI}#{type}/#{principal}"
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":member@Delete" => principal_path })
    end

    def has_member(sling, principal)
      detail = self.details(sling)
      members = detail["members"]
      if (members == nil)
        return false
      end
      return members.include?(principal)
    end
    
    def remove_member_viewer(sling, principal)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":member@Delete" => principal, ":viewer@Delete" => principal })
    end
    
    def add_member_viewer(sling, principal)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":member" => principal, ":viewer" => principal })
    end

    def remove_manager(sling, principal)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":manager@Delete" => principal })
    end

    def remove_viewer(sling, principal)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":viewer@Delete" => principal })
    end

    def remove_members(sling, principals)
      principal_paths = principals.collect do |principal|
        if principal.index("g-") == 0
          type = "group"
        else
          type = "user"
        end
        "/#{$USERMANAGER_URI}#{type}/#{principal}"
      end
      return sling.execute_post(sling.url_for("#{group_url}.update.html"),
              { ":member@Delete" => principal_paths })
    end

    def set_joinable(sling, joinable)
      return sling.execute_post(sling.url_for("#{group_url}.update.html"), "sakai:joinable" => joinable)
    end

    def members(sling)
      props = sling.get_node_props(group_url)
      return props["members"]
    end

    # Get the home folder of a group.
    def home_path_for(sling)
      return "/~#{@name}"
    end

    def self.url_for(name)
      return "#{$USERMANAGER_URI}group/#{name}"
    end

    private
    def group_url
      return Group.url_for(@name)
    end
  end


  class User < Principal
    attr_accessor :password
    attr_accessor :firstName
    attr_accessor :lastName
    attr_accessor :password
    attr_accessor :email

    def initialize(username, password=$DEFAULT_PASSWORD)
      super(username)
      @password = password
    end

    def self.admin_user
      return User.new("admin", "admin")
    end

    def self.anonymous
      return AnonymousUser.new
    end

    def do_request_auth(req)
      req.basic_auth(@name, @password)
    end

    def do_curl_auth(c)
      c.userpwd = "#{@name}:#{@password}"
    end

    def to_s
      return "User: #{@name} (pass: #{@password})"
    end

    def update_properties(sling, props)
      return sling.execute_post(sling.url_for("#{user_url}.update.html"), props)
    end

    def update_user(sling)
        data = {}
        if (!firstName.nil? and !lastName.nil? and !email.nil?)
            data[":sakai:profile-import"] = JSON.generate({'basic' => {'access' => 'everybody', 'elements' => {'email' => {'value' => email}, 'firstName' => {'value' => firstName}, 'lastName' => {'value' => lastName}}}})
            # data[":sakai:pages-template"] = "/var/templates/site/defaultuser"
        end

        if (!firstName.nil?)
            data["firstName"] = firstName
        end

        if (!lastName.nil?)
            data["lastName"] = lastName
        end

        if (!email.nil?)
            data["email"] = email
        end

        return update_properties(sling, data)
    end

	def change_password(sling, newpassword)
	   return sling.execute_post(sling.url_for("#{user_url}.changePassword.html"), "oldPwd" => @password, "newPwd" => newpassword, "newPwdConfirm" => newpassword)
	end


    # Get the home folder of a group.
    def home_path_for(sling)
      return "/~#{@name}"
    end


    def self.url_for(name)
      return "#{$USERMANAGER_URI}user/#{name}"
    end

    private
    def user_url
      return User.url_for(@name)
    end
  end

  class AnonymousUser < User

    def initialize()
      super("anonymous", "none")
    end

    def do_curl_auth(c)
      # do nothing
    end

    def do_request_auth(r)
      # do nothing
    end

  end

  class UserManager

    attr_accessor :log

    def initialize(sling)
      @sling = sling
      @date = Time.now().strftime("%Y%m%d%H%M%S%3N")
      @log = Logger.new(STDOUT)
      @log.level = Logger::WARN
    end

    def delete_test_user(id)
      return delete_user("testuser#{@date}-#{id}")
    end

    def delete_user(username)
      result = @sling.execute_post(@sling.url_for("#{User.url_for(username)}.delete.html"),
                                    { "go" => 1 })
      if (result.code.to_i > 299)
        @log.info "Error deleting user"
        return false
      end
      return true
    end

    def delete_group(groupname)
      result = @sling.execute_post(@sling.url_for("#{Group.url_for(groupname)}.delete.html"),
                                    { "go" => 1 })
      if (result.code.to_i > 299)
        @log.info "Error deleting group"
        return false
      end
      return true
    end

    def create_test_user(id)
      return create_user("testuser#{@date}-#{id}")
    end

    def create_user_object(user)
        data = { ":name" => user.name,
            "pwd" => user.password,
            "pwdConfirm" => user.password
        }

        if (!user.firstName.nil? and !user.lastName.nil? and !user.email.nil?)
            data[":sakai:profile-import"] = JSON.generate({'basic' => {'access' => 'everybody', 'elements' => {'email' => {'value' => user.email}, 'firstName' => {'value' => user.firstName}, 'lastName' => {'value' => user.lastName}}}})
            # data[":sakai:pages-template"] = "/var/templates/site/defaultuser"
        end

        if (!user.firstName.nil?)
            data["firstName"] = user.firstName
        end

        if (!user.lastName.nil?)
            data["lastName"] = user.lastName
        end

        if (!user.email.nil?)
            data["email"] = user.email
        else
            data["email"] = "#{user.firstName}@sakai.invalid"
        end

        result = @sling.execute_post(@sling.url_for("#{$USER_URI}"), data)
        if (result.code.to_i > 299)
            @log.info "Error creating user"
            return nil
        end
        return user
    end

    def create_user(username, firstname = nil, lastname = nil, email = nil)
      @log.info "Creating user: #{username}"
      user = User.new(username)
      user.firstName = firstname
      user.lastName = lastname
      user.email = email

      if user.email.nil?
          user.email = "#{username}@sakai.invalid"
      end

      return create_user_object(user)
    end
    
    def create_group(groupname, title = '')
        @log.info "Creating group: #{groupname}"
              group = Group.new(groupname)
      params = { "data" => JSON.generate({ 
        'id' => group.name,
        'title' => title,
        'description' => '',
        'visibility' => 'public',
        'joinability' => 'yes',
        'tags' => [],
        'worldTemplate' => '/var/templates/worlds/group/simple-group',
        '_charset_' => 'utf-8',
        'usersToAdd' => [{
          "userid" => "admin",
          "name" => "Admin",
          "firstname" => "Admin",
          "role" => "manager",
          "roleString" => "Manager",
          "creator" => "true"
        }]
      })}
      result = @sling.execute_post(@sling.url_for($GROUP_WORLD_URI), params)
      if (result.code.to_i > 299)
        @log.error(result.body)
        return nil
      end
      return group
    end
    
    def get_user_props(name)
      return @sling.get_node_props(User.url_for(name))
    end

    def get_group_props(name)
      return @sling.get_node_props(Group.url_for(name))
    end

  end

end
