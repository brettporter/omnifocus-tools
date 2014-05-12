#!/usr/bin/env ruby

# list-tasks.rb
#
# In this script we read from the XML files directly rather than the SQL
# database so that we might be able to identify any changes that have since
# been purged - for example if a large number of tasks seem to have been
# removed from statistic counts, this will help identify which tasks changed
# between versions
#
#  e.g. To see the difference between the current database and the backup
#       taken before a certain archive:
#
#    $ ./list-tasks.rb >current.txt
#    $ ./list-tasks.rb ~/Library/Containers/com.omnigroup.OmniFocus2/Data/Documents/OmniFocus\ 2014-05-12\ 115421\ before\ archive.ofocus-backup >2014-05-12.txt
#    $ diff 2014-05-12.txt current.txt
#

require 'rubygems'
require 'zip'
require 'nokogiri'

# Backup before archiva
#OF_DIRECTORY=File.expand_path('~/Library/Containers/com.omnigroup.OmniFocus2/Data/Documents')
#OF_FILENAME='OmniFocus 2014-05-12 115421 before archive.ofocus-backup'

# Backup
#OF_DIRECTORY=File.expand_path('~/Library/Containers/com.omnigroup.OmniFocus2/Data/Library/Application Support/OmniFocus/Backups')
#OF_FILENAME='OmniFocus 2014-05-12 115421.ofocus-backup'

# Archive
#OF_DIRECTORY=File.expand_path('~/Library/Containers/com.omnigroup.OmniFocus2/Data/Library/Application Support/OmniFocus')
#OF_FILENAME='Archive.ofocus-archive'

# Current
OF_DIRECTORY=File.expand_path('~/Library/Containers/com.omnigroup.OmniFocus2/Data/Library/Application Support/OmniFocus')
OF_FILENAME='OmniFocus.ofocus'

if ARGV.length > 0
  path = ARGV[0]
else
  path = "#{OF_DIRECTORY}/#{OF_FILENAME}"
end

tasks = {}

Dir["#{path}/*.zip"].each { |zip|

  Zip::File.open(zip) { |zip_file|
    content = zip_file.read('contents.xml')

    doc = Nokogiri::XML(content)
    doc.xpath('//xmlns:task[@id]').each { |task|
      id = task['id']
      n = task.at('name')
      name = n.text.tr("\n", " ") if n
      case task['op']
        when 'update'
          tasks[id] = name
        when 'reference'
          # skip references, probably not important for us - but double check
          # nothing unexpected
          fail "unexpected reference" unless tasks[id]
        when 'delete'
          tasks.delete id
        else
          # Not sure why, but in some transaction files there are tasks with
          # no op, and no name - don't add these
          tasks[id] = name if n
      end
    }
  }

}

# Note: tasks include project names, as projects are just tasks that have
# subtasks in the schema. In stats, these represent:
#  - Actions
#  - Action Groups
#  - Single Action Lists
#  - Projects
# When totalled, that should give the same as #{names.length}

names = tasks.values
names.sort!

puts names
