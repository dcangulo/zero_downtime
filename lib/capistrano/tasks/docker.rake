# ./lib/capistrano/tasks/docker.rake

namespace :docker do
  desc 'Create required network'
  task :create_network do
    on roles(:web) do
      execute :docker, 'network', 'create', 'backend', '|| echo "Network already exists!"'
    end
  end

  desc 'Create required volumes'
  task :create_volumes do
    on roles(:web) do
      execute :docker, 'volume', 'create', "app_log"
    end
  end

  desc 'Setup database'
  task :db_setup do
    on roles(:web) do
      within shared_path do
        execute(
          :docker,
          'run',
          '--rm',
          '--entrypoint bundle',
          '--network=backend',
          'zero-downtime',
          'exec rails db:setup'
        )
      end
    end
  end

  desc 'Start a new container'
  task :start_container do
    on roles(:web) do
      within shared_path do
        execute :docker, 'stop zero-downtime-app-new', '|| echo "Container is not running!"'
        execute :docker, 'rm zero-downtime-app-new', '|| echo "Container does not exist!"'
        execute(
          :docker,
          'create',
          '--name zero-downtime-app-new',
          '--volume app_log:/var/www/app/log',
          '--network=backend',
          '--env SECRET_KEY_BASE=b74f9df2edbb986f4da44425ccc6fcc4f23191515fa53dbdc4eebc549610',
          '--env RAILS_ENV=production',
          '--health-cmd="curl -f localhost:3000/ping"',
          '--health-interval=10s',
          '--health-timeout=1s',
          '--publish 3000:3000',
          'zero-downtime'
        )
        execute :docker, 'start', 'zero-downtime-app-new'
      end
    end
  end

  desc 'Wait for container'
  task :wait_for_container do
    on roles(:web) do
      execute <<-EOCMD
        while [ "$(docker container inspect -f '{{.State.Health.Status}}' zero-downtime-app-new)" != "healthy" ]
          do sleep 1
        done
      EOCMD
    end
  end

  desc 'Stop old container'
  task :stop_container do
    on roles(:web) do
      within shared_path do
        execute :docker, 'stop', 'zero-downtime-app', '|| echo "Container is not running!"'
        execute :docker, 'rm', 'zero-downtime-app', '|| echo "Container not found!"'
      end
    end
  end

  desc 'Rename new container'
  task :rename_container do
    on roles(:web) do
      within shared_path do
        execute :docker, 'container', 'rename', 'zero-downtime-app-new', 'zero-downtime-app'
      end
    end
  end
end
