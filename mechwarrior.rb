#!/usr/bin/env ruby

require 'commander/import'
require 'yaml'
require 'command_line_reporter'
require 'mechanize'

program :name, 'Mechwarrior'
program :version, '0.0.1'
program :description, 'private torrent metasearching'
 
command :search do |c|
  c.syntax = 'mechwarrior search [options]'
  c.description = 'Searches the torrent sites'
  c.option '-y', '--year INTEGER', Integer, 'The year of the torrent'
  c.option '-t', '--tags STRING', String, 'A comma separated list of tags'
  c.option '-f', '--filelist STRING', String, 'A string to search in file list'
  c.option '-d', '--description STRING', String, 'A string to search torrent description'
  # c.option '-ob', '--orderby STRING', String, 'What to order the search results by'
  # c.option '-ow', '--orderway STRING', String, 'How to order the search results'
  # c.option '--sites LIST', String, 'A list of the sites to search'
  c.action do |args, options|
    agent = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }

    config = YAML.load_file('sites.yml')

    config.each do |site|
      site = site[1]
      base_url = site["login"].split(/login/)[0]

      page = agent.post(site["login"], {
        "username": site["username"],
        "password": site["password"],
        "loginSubmit": "Login"
      })
      params = "&year=#{options.year}&taglist=#{options.tags}&description=#{options.description}"
      page = agent.get("#{site["search"]}#{args[0]}#{params}")

      p page.search('.group').text.gsub(/[\t\n]/, "").inspect
    end

    # Table.new.puts(search_obj)

  end
end

command :init do |c|
  c.syntax = 'mechwarrior init'
  c.description = 'initializes mechawarrior and asks for private torrent site credentials'
  c.action do |args, options|
    config = YAML.load_file('sites.yml')
    config.each do |site|
      agree("#{site[0]}? ")
      username = ask 'Username: ', String
      password = ask('Password: ', String) { |q| q.echo = "*" }
      site[1]["username"] = "#{username.to_s}"
      site[1]["password"] = "#{password.to_s}"
      File.open('sites.yml', 'w') {|f| f.write config.to_yaml }
    end
  end
end

class Table
  include CommandLineReporter

   def puts(json_obj)
    table(:border => true) do
      row do
        column('ARTIST', :width => 20)
        column('ALBUM', :width => 30)
        column('YEAR', :width => 15)
        column('SIZE', :width => 15)
        column('SNATCHED', :width => 15)
        column('SEEDERS', :width => 15)
        column('LEECHERS', :width => 15)
      end
      json_obj.each do
        row do
          column()
          column()
          column()
          column()
          column()
          column()
          column()
        end
      end
   end
  end
end