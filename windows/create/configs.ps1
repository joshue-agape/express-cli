# =================================
# Express Project CLI - Configurations
# =================================
$tsconfig_content_express_ts = @'
    {
        "compilerOptions": {
            "rootDir": "./",
            "outDir": "./dist",
            "allowImportingTsExtensions": true,
            "noEmit": true,

            "module": "NodeNext",
            "moduleResolution": "NodeNext",
            "target": "ESNext",

            "types": ["node", "jest"],

            "strict": true,
            "esModuleInterop": true,
            "skipLibCheck": true,

            "noUncheckedIndexedAccess": true,
            "verbatimModuleSyntax": true,
            "isolatedModules": true,
            "forceConsistentCasingInFileNames": true
        },
        "ts-node": {
            "esm": true,
            "experimentalSpecifierResolution": "node"
        },
        "include": ["app/**/*.ts", "tests/**/*.ts"]
    }
'@

$env_mysql_content_express_ts = @'
PORT=3000
NODE_ENV=development

SESSION_SECRET=session-secret-key
SWAGGER_USER=swagger_user
SWAGGER_PASSWORD=swagger_password

DB_NAME=database_name
DB_USER=root
DB_PASSWORD=database_password
DB_HOST=localhost
DB_PORT=3306
DIALECT=mysql

'@

$env_mysql_configs_content = @'
    import dotenv from 'dotenv';

    dotenv.config();

    export const config = {
        port: process.env.PORT || 3000,
        nodeEnv: process.env.NODE_ENV || 'development',
        sessionSecret: process.env.SESSION_SECRET || 'session-secret-key',
        swaggerUser: process.env.SWAGGER_USER || 'admin',
        swaggerPassword: process.env.SWAGGER_PASSWORD || 'admin@2026',
        db: {
            name: process.env.DB_NAME || 'mysql',
            user: process.env.DB_USER || 'root',
            password: process.env.DB_PASSWORD || '',
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '3306', 10),
            dialect: process.env.DIALECT || 'mysql',
        },
    };
'@

$env_postgres_content_express_ts = @'
PORT=3000
NODE_ENV=development

SESSION_SECRET=session-secret-key
SWAGGER_USER=swagger_user
SWAGGER_PASSWORD=swagger_password

DB_NAME=database_name
DB_USER=postgres
DB_PASSWORD=database_password
DB_HOST=localhost
DB_PORT=5432
DIALECT=postgres

'@

$env_postgresql_configs_content = @'
    import dotenv from 'dotenv';

    dotenv.config();

    export const config = {
        port: process.env.PORT || 3000,
        nodeEnv: process.env.NODE_ENV || 'development',
        sessionSecret: process.env.SESSION_SECRET || 'session-secret-key',
        swaggerUser: process.env.SWAGGER_USER || 'admin',
        swaggerPassword: process.env.SWAGGER_PASSWORD || 'admin@2026',
        db: {
            name: process.env.DB_NAME || 'postgres',
            user: process.env.DB_USER || 'postgres',
            password: process.env.DB_PASSWORD || '',
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '5432', 10),
            dialect: process.env.DIALECT || 'postgres',
        },
    };
'@

$env_sqlite_content_express_ts = @'
PORT=3000
NODE_ENV=development

SESSION_SECRET=session-secret-key
SWAGGER_USER=swagger_user
SWAGGER_PASSWORD=swagger_password

DIALECT=sqlite
DB_STORAGE=./src/database.sqlite

'@

$env_sqlite_configs_content = @'
    import dotenv from 'dotenv';

    dotenv.config();

    export const config = {
        port: process.env.PORT || 3000,
        nodeEnv: process.env.NODE_ENV || 'development',
        sessionSecret: process.env.SESSION_SECRET || 'session-secret-key',
        swaggerUser: process.env.SWAGGER_USER || 'admin',
        swaggerPassword: process.env.SWAGGER_PASSWORD || 'admin@2026',
        db: {
            DB_STORAGE: process.env.DB_STORAGE || './src/database.sqlite',
            dialect: process.env.DIALECT || 'sqlite',
        },
    };
'@

$env_sqlserver_content_express_ts = @'
PORT=3000
NODE_ENV=development

SESSION_SECRET=session-secret-key
SWAGGER_USER=swagger_user
SWAGGER_PASSWORD=swagger_password

DB_NAME=database_name
DB_USER=sa
DB_PASSWORD=database_password
DB_HOST=localhost
DB_PORT=1433
DIALECT=mssql

'@

$env_sqlserver_configs_content = @'
    import dotenv from 'dotenv';

    dotenv.config();

    export const config = {
        port: process.env.PORT || 3000,
        nodeEnv: process.env.NODE_ENV || 'development',
        sessionSecret: process.env.SESSION_SECRET || 'session-secret-key',
        swaggerUser: process.env.SWAGGER_USER || 'admin',
        swaggerPassword: process.env.SWAGGER_PASSWORD || 'admin@2026',
        db: {
            name: process.env.DB_NAME || 'db_name',
            user: process.env.DB_USER || 'sa',
            password: process.env.DB_PASSWORD || '',
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '1433', 10),
            dialect: process.env.DIALECT || 'mssql',
            dialectOptions: {
                options: {
                    encrypt: true,
                    trustServerCertificate: true,
                },
            },
        },
    };
'@

$env_mongodb_content_express_ts = @'
PORT=3000
NODE_ENV=development

SESSION_SECRET=session-secret-key
SWAGGER_USER=swagger_user
SWAGGER_PASSWORD=swagger_password

DB_URL=mongodb://localhost:27017/database_name
DIALECT=mongodb

'@

$env_mongodb_configs_content = @'
    import dotenv from 'dotenv';

    dotenv.config();

    export const config = {
        port: process.env.PORT || 3000,
        nodeEnv: process.env.NODE_ENV || 'development',
        sessionSecret: process.env.SESSION_SECRET || 'session-secret-key',
        swaggerUser: process.env.SWAGGER_USER || 'admin',
        swaggerPassword: process.env.SWAGGER_PASSWORD || 'admin@2026',
        db: {
            DB_URL: process.env.DB_URL || 'mongodb://localhost:27017/database_name',
            dialect: process.env.DIALECT || 'mongodb',
        },
    };
'@


# =================================
# Prettier Configurations
# =================================
$prettierrc_content_express_ts = @'
    {
        "semi": true,
        "trailingComma": "all",
        "singleQuote": true,
        "printWidth": 120,
        "tabWidth": 4
    }
'@

$prettierignore_content_express_ts = @'
node_modules
dist
package-lock.json
'@

$gitignore_content_express_ts = @'
node_modules
dist
.env
package-lock.json
'@