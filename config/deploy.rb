require 'bundler/capistrano'
require 'capistrano-unicorn'

# Application settings
set :application, 'redmine'
set :user,        'suitepad'
set :group,       'suitepad'

# Repository settings
set :scm,         :git
set :repository,  'git@github.com:suitepad-gmbh/redmine.git'
set :ssh_options, { :port => 2899 } # Use 2899 port instead of default 22
set :branch,      'master'

# Server settings
server 'app-server-05.suitepad.de', :app, :web, :db, :primary => true
set(:deploy_to) { "/home/suitepad/web/#{application}" }
set :use_sudo,  false


################################################################################
# Set additional symbolic links, move files, backups stuff, set rackspace
# config if needed
################################################################################
namespace :configure do
  task :set_config_link, :roles => :app do
    run "ln -s #{shared_path}/config/* #{current_release}/config/"
  end

  task :set_uploads_link, :roles => :app do
    run "rm -rf #{current_release}/files"
    run "ln -s #{shared_path}/files #{current_release}/files"
  end

  task :set_socket_symlink, :roles => :app do
    run "rm -rf #{current_release}/tmp/sockets"
    run "ln -s #{shared_path}/sockets #{current_release}/tmp/sockets"
  end
end


################################################################################
# Database tasks
################################################################################
namespace :db do

  desc "Create Production Database"
  task :create do
    puts "\n\n=== Creating the Production Database! ===\n\n"
    run "cd #{current_path}; bundle exec rake db:create RAILS_ENV=#{rails_env}"
    system "cap deploy:set_permissions"
  end

  desc "Migrate Production Database"
  task :migrate do
    puts "\n\n=== Migrating the Production Database! ===\n\n"
    run "cd #{current_path}; bundle exec rake db:migrate RAILS_ENV=#{rails_env}"
    system "cap deploy:set_permissions"
  end

  desc "Resets the Production Database"
  task :migrate_reset do
    puts "\n\n=== Resetting the Production Database! ===\n\n"
    run "cd #{current_path}; bundle exec rake db:migrate:reset RAILS_ENV=#{rails_env}"
  end

  desc "Destroys Production Database"
  task :drop do
    puts "\n\n=== Destroying the Production Database! ===\n\n"
    run "cd #{current_path}; bundle exec rake db:drop RAILS_ENV=#{rails_env}"
    system "cap deploy:set_permissions"
  end

  desc "Populates the Production Database"
  task :seed do
    puts "\n\n=== Populating the Production Database! ===\n\n"
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=#{rails_env}"
  end

end


# Run migrations after updating code
# before 'deploy:restart', 'deploy:migrate'

# Tasks to do before asset compiling
before 'bundle:install' do
  configure.set_config_link
  configure.set_uploads_link
  configure.set_socket_symlink
end

# After restart hooks
after 'deploy:restart' do
  unicorn.restart
end