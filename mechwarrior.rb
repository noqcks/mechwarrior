#!/usr/bin/env ruby

require 'commander/import'
require 'yaml'
require 'command_line_reporter'
require 'mechanize'
require 'json'

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
  c.option '-s', '--sites LIST', Array, 'A list of sites to search'
  # gazelle sites
  c.action do |args, options|
    agent = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    config = YAML.load_file('sites.yml')
    config.each do |site|
      $site = site[1]
      $base_url = $site["login"].split(/login/)[0]
      if (options.sites == nil) || (options.sites.include? $site)
        page = agent.post($site["login"], {
          "username": $site["username"],
          "password": $site["password"],
          "loginSubmit": "Login"
        })
        params = "&year=#{options.year}&taglist=#{options.tags}&description=#{options.description}"
        page = agent.get("#{$site["search"]}#{args[0]}#{params}")

        results = JSON.parse(page.body)['response']['results']
        Table.new.puts(results)
      end
    end
  end
end

command :init do |c|
  c.syntax = 'mechwarrior init'
  c.description = 'initializes mechawarrior and asks for private torrent site credentials'
  c.action do |args, options|
    config = YAML.load_file('sites.yml')
    config.each do |site|
      say "Do you have access to:"
      if agree("#{site[0]}? ") === true
        username = ask 'Username: ', String
        password = ask('Password: ', String) { |q| q.echo = "*" }
        site[1]["username"] = "#{username.to_s}"
        site[1]["password"] = "#{password.to_s}"
        File.open('sites.yml', 'w') {|f| f.write config.to_yaml }
      end
    end
  end
end

class Table
  include CommandLineReporter
  def puts(json_obj)
    config = YAML.load_file('sites.yml')
    table(:border => true) do 
      row do
        $site['columns'].each do |key,value|
          column(key, :width => 20)
        end
        column('LINK', :width => 50)
      end
      json_obj.each do |x|
        row do
          $site['columns'].each do |key,value|
            column(x[value], :width => 10)
          end
          column($base_url + 'torrents.php?id=' + x['groupId'].to_s, :width => 50)
        end
      end
    end unless json_obj.empty?
  end
end