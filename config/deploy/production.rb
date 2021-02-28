# ./config/deploy/development.rb

set :stage, :development
set :branch, 'master'

set :deploy_to, '~/www/zero_downtime'

role :web, ['deploy@159.89.204.113']
