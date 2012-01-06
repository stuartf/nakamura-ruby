require 'test/unit.rb'
require 'nakamura'
require 'nakamura/users'
require 'nakamura/file'
require 'nakamura/search'
require 'tempfile'
require 'logger'

module SlingTest

  @@log_level = Logger::DEBUG

  def SlingTest.setLogLevel(level)
    @@log_level = level
  end

  def setup
    @s = SlingInterface::Sling.new()
    @um = SlingUsers::UserManager.new(@s)
    @search = SlingSearch::SearchManager.new(@s)
    @created_nodes = []
    @created_users = []
    @created_groups = []
    @delete = true
    @log = Logger.new(STDOUT)
    @log.level = @@log_level
  end

  def teardown
    if ( @delete ) then
      @s.switch_user(SlingUsers::User.admin_user)
      @created_nodes.reverse.each { |n| @s.delete_node(n) }
      @created_groups.each { |g| @um.delete_group(g) }
      @created_users.each { |u| @um.delete_user(u.name) }
    end
  end

  def create_node(path, props={})
    #puts "Path is #{path}"
    res = @s.create_node(path, props)
    assert_not_equal("500", res.code, "Expected to be able to create node "+res.body)
    @created_nodes << path
    return path
  end

  def create_file_node(path, fieldname, filename, data, content_type="text/plain")
    res = @s.create_file_node(path, fieldname, filename, data, content_type)
    @created_nodes << path unless @created_nodes.include?(path)
    return res
  end

  def create_pooled_content(filename, content, props={})
    properties = {}
    properties.merge!(props)
    properties['sakai:pooled-content-file-name'] = filename
    properties['content'] = content

    url = '/system/pool/createfile'
    res = @s.create_node(url, properties)

    assert_not_nil(res)
    assert_equal(true, res.code.to_i >= 200 && res.code.to_i < 300, "Expected to be able to create node #{res.body}")
    json = JSON.parse(res.body)
    assert_not_nil(json['_contentItem'])
    assert_not_nil(json['_contentItem']['poolId'])

    path = "/p/#{json['_contentItem']['poolId']}"
    @created_nodes << path unless @created_nodes.include?(path)
    return path
  end

  def create_user(username, firstname = nil, lastname = nil)
    u = @um.create_user(username, firstname, lastname)
    assert_not_nil(u, "Expected user to be created: #{username}")
    @created_users << u
    return u
  end

  def create_test_user(i)
    u = @um.create_test_user(i)
    assert_not_nil(u, "Expected user to be created: #{i}")
    @created_users << u
    return u
  end

  def create_group(groupname, title = nil)
    g = @um.create_group(groupname, title)
    assert_not_nil(g, "Expected group to be created: #{groupname}")
    @created_groups << groupname
    return g
  end

  def uniqueness()
    Time.now.to_f.to_s.gsub(".", "")
  end

  def wait_for_indexer()
    magic_content = "#{uniqueness()}_#{rand(1000).to_s}"
    filename = "wait_for_indexer_#{magic_content}"

    fm = SlingFile::FileManager.new(@s)
    fm.upload_pooled_file(filename, magic_content, 'text/plain')

    # Give the indexer up to 20 seconds to catch up, but stop waiting early if
    # we find our test item has landed in the index.
    20.times do
      res = @s.execute_get(@s.url_for("/var/search/files/allfiles.json?q=#{filename}"))
      if JSON.parse(res.body)["total"] != 0
          break
      end
      sleep(1)
    end
  end

end

