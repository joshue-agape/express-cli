. "$PSScriptRoot\configs.ps1"
. "$PSScriptRoot\db-configs.ps1"
. "$PSScriptRoot\default-code.ps1"
. "$PSScriptRoot\docs-configs.ps1"


function New-ExpressApp {
    param(
        [string]$project_name
    )

    if (-not $project_name) {
        $project_name = Read-Host "Project name "
    }

    New-Item -ItemType Directory -Path $project_name -Force | Out-Null
    Set-Location $project_name
    
    Write-Host "Initializing Node project"
    npm init
    
    Write-Host "`n--- Database Selection ---" -ForegroundColor Cyan
    Write-Host "1. MySQL / MariaDB"
    Write-Host "2. PostgreSQL"
    Write-Host "3. SQL Server"
    Write-Host "4. MongoDB (NoSQL)"
    Write-Host "5. SQLite"

    $db_choice = Read-Host "Select your database (1-5)"

    $dirs = @(
        "app/controllers",
        "app/repositories",
        "app/routes/v1",
        "app/services",
        "configs",
        "tests",
        "docs/users-api-docs"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Write-Host "Installing dependencies (Production)"
    npm install dotenv express merge-yaml swagger-ui-express yamljs cors express-session cookie-parser express-basic-auth node-cron

    Write-Host "Installing dependencies for database support"
    switch ($db_choice) {
        "1" {
            npm install sequelize mysql2
            Set-Content ".env" -Value $env_mysql_content_express_ts -Encoding UTF8
            Set-Content ".env.example" -Value $env_mysql_content_express_ts -Encoding UTF8
            Set-Content "configs/env.ts" -Value $env_mysql_configs_content -Encoding UTF8
        }
        "2" {
            npm install sequelize pg pg-hstore
            Set-Content ".env" -Value $env_postgres_content_express_ts -Encoding UTF8
            Set-Content ".env.example" -Value $env_postgres_content_express_ts -Encoding UTF8
            Set-Content "configs/env.ts" -Value $env_postgresql_configs_content -Encoding UTF8
        }
        "3" {
            npm install sequelize tedious
            Set-Content ".env" -Value $env_sqlserver_content_express_ts -Encoding UTF8
            Set-Content ".env.example" -Value $env_sqlserver_content_express_ts -Encoding UTF8
            Set-Content "configs/env.ts" -Value $env_sqlserver_configs_content -Encoding UTF8
        }
        "4" {
            npm install sequelize mongoose
            Set-Content ".env" -Value $env_mongodb_content_express_ts -Encoding UTF8
            Set-Content ".env.example" -Value $env_mongodb_content_express_ts -Encoding UTF8
            Set-Content "configs/env.ts" -Value $env_mongodb_configs_content -Encoding UTF8
        }
        "5" {
            npm install sequelize sqlite3
            Set-Content ".env" -Value $env_sqlite_content_express_ts -Encoding UTF8
            Set-Content ".env.example" -Value $env_sqlite_content_express_ts -Encoding UTF8
            Set-Content "configs/env.ts" -Value $env_sqlite_configs_content -Encoding UTF8
        }
        default {
            Write-Host "Invalid choice. Using PostgreSQL by default."
            npm install sequelize pg pg-hstore
            Set-Content ".env" -Value $env_postgres_content_express_ts -Encoding UTF8
            Set-Content ".env.example" -Value $env_postgres_content_express_ts -Encoding UTF8
            Set-Content "configs/env.ts" -Value $env_postgresql_configs_content -Encoding UTF8
        }
    }

    Write-Host "Installing dependencies (Development)"
    npm install -D @types/express @types/jest @types/node @types/supertest @types/swagger-ui-express @types/yamljs copyfiles jest prettier rimraf supertest ts-jest ts-node-dev tsx typescript @types/cors @types/express-session @types/cookie-parser @types/validator @types/lodash sequelize-cli

    Set-Content "tsconfig.json" -Value $tsconfig_content_express_ts -Encoding UTF8
    Set-Content "main.ts" -Value $main_content_express_ts -Encoding UTF8
    Set-Content "jest.config.cjs" -Value $jest_config_content_express_ts -Encoding UTF8
    Set-Content ".sequelizerc" -Value $sequelize_config_content_express_ts -Encoding UTF8
    Set-Content ".prettierrc" -Value $prettierrc_content_express_ts -Encoding UTF8
    Set-Content ".gitignore" -Value $gitignore_content_express_ts -Encoding UTF8
    Set-Content ".prettierignore" -Value $prettierignore_content_express_ts -Encoding UTF8
    Set-Content "tests/index.ts" -Value $jest_index_content_express_ts -Encoding UTF8
    Set-Content "tests/user.test.ts" -Value $jest_user_content_express_ts -Encoding UTF8
    Set-Content "docs/main.yaml" -Value $docs_main_yaml_content_express_ts -Encoding UTF8
    Set-Content "docs/users-api-docs/create.yaml" -Value $docs_create_user_yaml_content_express_ts -Encoding UTF8
    Set-Content "docs/users-api-docs/find-all.yaml" -Value $docs_find_all_users_yaml_content_express_ts -Encoding UTF8
    Set-Content "app/controllers/user.controller.ts" -Value $controller_user_content_express_ts -Encoding UTF8
    Set-Content "app/repositories/BaseRepository.ts" -Value $repository_base_content_express_ts -Encoding UTF8
    Set-Content "app/repositories/UserRepository.ts" -Value $repository_user_content_express_ts -Encoding UTF8
    Set-Content "app/routes/v1/user.ts" -Value $routes_user_content_express_ts -Encoding UTF8
    Set-Content "app/routes/index.ts" -Value $routes_index_content_express_ts -Encoding UTF8
    Set-Content "app/services/ResponseService.ts" -Value $service_response_content_express_ts -Encoding UTF8
    Set-Content "app/services/TokenCleanupService.ts" -Value $service_token_cleanup_content_express_ts -Encoding UTF8

    npx sequelize-cli init

    Remove-Item "database/models/index.js" -Force -ErrorAction SilentlyContinue
    Set-Content "configs/database.ts" -Value $sequelize_configs_database_content_express_ts -Encoding UTF8
    Set-Content "database/migrations/1-create-user.ts" -Value $sequelize_migrations_user_content_express_ts -Encoding UTF8
    Set-Content "database/migrations/2-create-token.ts" -Value $sequelize_migrations_token_content_express_ts -Encoding UTF8
    Set-Content "database/models/index.ts" -Value $sequelize_model_index_content -Encoding UTF8
    Set-Content "database/models/user.ts" -Value $sequelize_model_user_content_express_ts -Encoding UTF8
    Set-Content "database/models/token.ts" -Value $sequelize_model_token_content_express_ts -Encoding UTF8
    Set-Content "database/seeders/user.ts" -Value $sequelize_seeds_user_content_express_ts -Encoding UTF8

    npm pkg set main="main.ts"
    npm pkg set type="module"
    npm pkg set scripts.dev="tsx watch main.ts"
    npm pkg set scripts.clean="rimraf dist"
    npm pkg set scripts.build="npm run clean && npx tsc && npx copyfiles -u 0 docs/*.yaml dist/"
    npm pkg set scripts.start="node dist/main.js"
    npm pkg set scripts.format="prettier --write ."
    npm pkg set scripts.check-format="prettier --check ."
    npm pkg set scripts.test="node --experimental-vm-modules node_modules/jest/bin/jest.js --forceExit"
    npm pkg set scripts.test:watch="npm test -- --watchAll"
    npm pkg set scripts.test:cov="npm test -- --coverage"
    npm pkg set scripts.db:create="npx sequelize-cli db:create"
    npm pkg set scripts.db:drop="npx sequelize-cli db:drop"
    npm pkg set scripts.db:migrate="npx sequelize-cli db:migrate"
    npm pkg set scripts.db:migrate:fresh="npx sequelize-cli db:migrate:undo"
    npm pkg set scripts.db:migrate:fresh:all="npx sequelize-cli db:migrate:undo:all"
    npm pkg set scripts.db:seed="npx sequelize-cli db:seed:all"
    npm pkg set scripts.db:seed:fresh="npx sequelize-cli db:seed:undo"
    npm pkg set scripts.db:seed:fresh:all="npx sequelize-cli db:seed:undo:all"
    
    Write-Host "Formatting project code..."
    npm run format
    
    $GIT = Read-Host "Would you like to initialize Git? (Y/N)"
    if ($GIT.Trim() -match '^[Yy]') {
        git init
        git add -A
        git commit -m "Initial commit"
    }

    Write-Host "Project setup done! Happy coding"
}