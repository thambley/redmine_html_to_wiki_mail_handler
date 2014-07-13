namespace :redmine do
  namespace :plugins do
    namespace :html_to_wiki_mail_handler do
      PLUGIN_NAME='redmine_html_to_wiki_mail_handler'

      desc 'Runs the html_to_wiki_mail_handler tests.'
      task :test do
        Rake::Task["redmine:plugins:html_to_wiki_mail_handler:test:ui"].invoke
        Rake::Task["redmine:plugins:html_to_wiki_mail_handler:test:units"].invoke
        Rake::Task["redmine:plugins:html_to_wiki_mail_handler:test:functionals"].invoke
        Rake::Task["redmine:plugins:html_to_wiki_mail_handler:test:integration"].invoke
      end

      namespace :test do
        desc 'Runs the plugins unit tests.'
        Rake::TestTask.new :ui => "db:test:prepare" do |t|
          t.libs << "test"
          t.verbose = true
          t.pattern = "plugins/#{PLUGIN_NAME}/test/ui/**/*_test.rb"
        end

        desc 'Runs the plugins unit tests.'
        Rake::TestTask.new :units => "db:test:prepare" do |t|
          t.libs << "test"
          t.verbose = true
          t.pattern = "plugins/#{PLUGIN_NAME}/test/unit/**/*_test.rb"
        end

        desc 'Runs the plugins functional tests.'
        Rake::TestTask.new :functionals => "db:test:prepare" do |t|
          t.libs << "test"
          t.verbose = true
          t.pattern = "plugins/#{PLUGIN_NAME}/test/functional/**/*_test.rb"
        end

        desc 'Runs the plugins integration tests.'
        Rake::TestTask.new :integration => "db:test:prepare" do |t|
          t.libs << "test"
          t.verbose = true
          t.pattern = "plugins/#{PLUGIN_NAME}/test/integration/**/*_test.rb"
        end
      end


      namespace :coveralls do
        desc "Push latest coverage results to Coveralls.io"
        require 'coveralls/rake/task'

        Coveralls::RakeTask.new
        task :test => ['redmine:plugins:html_to_wiki_mail_handler:test', 'coveralls:push']
      end
    end
  end
end