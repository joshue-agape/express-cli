$sequelize_config_content_express_ts = @'
    const path = require('path');

    module.exports = {
        'config': path.resolve('configs', 'database.ts'),
        'models-path': path.resolve('database', 'models'),
        'seeders-path': path.resolve('database', 'seeders'),
        'migrations-path': path.resolve('database', 'migrations')
    };
'@

$sequelize_migrations_user_content_express_ts = @'
    import { QueryInterface, DataTypes } from 'sequelize';

    /** @type {import('sequelize-cli').Migration} */
    export async function up(queryInterface: QueryInterface) {
        await queryInterface.createTable('users', {
            user_id: {
                type: DataTypes.INTEGER,
                allowNull: false,
                autoIncrement: true,
                primaryKey: true,
            },
            name: {
                type: DataTypes.STRING,
                allowNull: false,
            },
            email: {
                type: DataTypes.STRING,
                unique: true,
                allowNull: false,
            },
            status: {
                type: DataTypes.ENUM('connected', 'disconnected'),
                allowNull: false,
                defaultValue: 'disconnected',
            },
            createdAt: {
                allowNull: false,
                type: DataTypes.DATE,
                defaultValue: new Date(),
            },
            updatedAt: {
                allowNull: false,
                type: DataTypes.DATE,
                defaultValue: new Date(),
            },
        });

        const dialect = queryInterface.sequelize.getDialect();
        if (dialect === 'postgres') {
            await queryInterface.sequelize.query('ALTER SEQUENCE "users_user_id_seq" RESTART WITH 100000;');
        }
    }

    export async function down(queryInterface: QueryInterface) {
        await queryInterface.dropTable('users');
        const dialect = queryInterface.sequelize.getDialect();
        if (dialect === 'postgres') {
            await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_users_status" CASCADE;');
        }
    }
'@

$sequelize_migrations_token_content_express_ts = @'
    import { QueryInterface, DataTypes } from 'sequelize';

    /** @type {import('sequelize-cli').Migration} */
    export async function up(queryInterface: QueryInterface) {
        await queryInterface.createTable('tokens', {
            token_id: {
                type: DataTypes.INTEGER,
                allowNull: false,
                autoIncrement: true,
                primaryKey: true,
            },
            user_id: {
                type: DataTypes.INTEGER,
                allowNull: false,
                references: { model: 'users', key: 'user_id' },
                onUpdate: 'CASCADE',
                onDelete: 'CASCADE',
            },
            token: {
                type: DataTypes.TEXT,
                allowNull: false,
                unique: true,
            },
            token_type: {
                type: DataTypes.ENUM('access', 'refresh'),
                allowNull: false,
                defaultValue: 'access',
            },
            token_status: {
                type: DataTypes.ENUM('active', 'revoked'),
                allowNull: false,
                defaultValue: 'active',
            },
            expires_at: {
                type: DataTypes.DATE,
                allowNull: false,
            },
            createdAt: {
                allowNull: false,
                type: DataTypes.DATE,
                defaultValue: new Date(),
            },
            updatedAt: {
                allowNull: false,
                type: DataTypes.DATE,
                defaultValue: new Date(),
            },
        });
        
        await queryInterface.addIndex('tokens', ['token']);
        await queryInterface.addIndex('tokens', ['user_id', 'token_status']);
    }

    export async function down(queryInterface: QueryInterface) {
        await queryInterface.dropTable('tokens');
        const dialect = queryInterface.sequelize.getDialect();
        if (dialect === 'postgres') {
            await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_tokens_token_type";');
            await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_tokens_token_status";');
        }
    }
'@

$sequelize_model_index_content = @'
    import fs from 'fs';
    import path from 'path';
    import { fileURLToPath, pathToFileURL } from 'url';
    import { Sequelize, DataTypes } from 'sequelize';
    import databaseConfig from '../../configs/database.ts';
    import { config as envConfig } from '../../configs/env.ts';

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const basename = path.basename(__filename);

    const env = envConfig.nodeEnv || 'development';
    // @ts-ignore
    const config = databaseConfig[env];

    const db: any = {};

    const sequelize = new Sequelize(config.database, config.username, config.password, config);

    const files = fs.readdirSync(__dirname).filter((file) => {
        return file.indexOf('.') !== 0 && file !== basename && (file.slice(-3) === '.ts' || file.slice(-3) === '.js') && file.indexOf('.test.ts') === -1;
    });

    for (const file of files) {
        const filePath = path.join(__dirname, file);
        const fileUrl = pathToFileURL(filePath).href;

        const modelModule = await import(fileUrl);

        if (typeof modelModule.default === 'function') {
            const model = modelModule.default(sequelize, DataTypes);
            db[model.name] = model;
        }
    }

    Object.keys(db).forEach((modelName) => {
        if (db[modelName].associate) {
            db[modelName].associate(db);
        }
    });

    db.sequelize = sequelize;
    db.Sequelize = Sequelize;

    export { sequelize, Sequelize };
    export default db;
'@

$sequelize_model_user_content_express_ts = @'
    import { Model, DataTypes } from 'sequelize';
    import type { Sequelize, CreationOptional, InferAttributes, NonAttribute, InferCreationAttributes } from 'sequelize';

    export default (sequelize: Sequelize, dataTypes: typeof DataTypes) => {
        class User extends Model<InferAttributes<User>, InferCreationAttributes<User>> {
            declare user_id: CreationOptional<number>;
            declare name: string;
            declare email: string;
            declare status: 'connected' | 'disconnected';
            declare createdAt: CreationOptional<Date>;
            declare updatedAt: CreationOptional<Date>;

            declare Tokens?: NonAttribute<any[]>;
            
            static associate(models: any) {
                User.hasMany(models.Token, { foreignKey: 'user_id', as: 'Tokens' });
            }
        }

        User.init(
            {
                user_id: {
                    type: dataTypes.INTEGER,
                    autoIncrement: true,
                    primaryKey: true,
                },
                name: {
                    type: dataTypes.STRING,
                    allowNull: false,
                },
                email: {
                    type: dataTypes.STRING,
                    allowNull: false,
                    unique: true,
                    validate: { isEmail: true },
                },
                status: {
                    type: dataTypes.ENUM('connected', 'disconnected'),
                    allowNull: false,
                    defaultValue: 'disconnected',
                },
                createdAt: {
                    type: dataTypes.DATE,
                    allowNull: false,
                },
                updatedAt: {
                    type: dataTypes.DATE,
                    allowNull: false,
                },
            },
            {
                sequelize,
                modelName: 'User',
                tableName: 'users',
                timestamps: true,
            },
        );

        return User;
    };
'@

$sequelize_model_token_content_express_ts = @'
    import { Model, DataTypes } from 'sequelize';
    import type { Sequelize, CreationOptional, InferAttributes, NonAttribute, InferCreationAttributes } from 'sequelize';

    export default (sequelize: Sequelize, dataTypes: typeof DataTypes) => {
        class Token extends Model<InferAttributes<Token>, InferCreationAttributes<Token>> {
            declare token_id: CreationOptional<number>;
            declare user_id: number;
            declare token: string;
            declare token_type: 'access' | 'refresh';
            declare token_status: 'active' | 'revoked';
            declare expires_at: Date;

            declare User?: NonAttribute<any>;

            static associate(models: any) {
                Token.belongsTo(models.User, { foreignKey: 'user_id', as: 'User' });
            }
        }

        Token.init(
            {
                token_id: {
                    type: dataTypes.INTEGER,
                    autoIncrement: true,
                    primaryKey: true,
                },
                user_id: {
                    type: dataTypes.INTEGER,
                    allowNull: false,
                    references: { model: 'users', key: 'user_id' },
                },
                token: {
                    type: dataTypes.TEXT,
                    allowNull: false,
                    unique: true,
                },
                token_type: {
                    type: dataTypes.ENUM('access', 'refresh'),
                    allowNull: false,
                    defaultValue: 'access',
                },
                token_status: {
                    type: dataTypes.ENUM('active', 'revoked'),
                    allowNull: false,
                    defaultValue: 'active',
                },
                expires_at: {
                    type: dataTypes.DATE,
                    allowNull: false,
                },
            },
            {
                sequelize,
                modelName: 'Token',
                tableName: 'tokens',
                timestamps: true,
            },
        );

        return Token;
    };
'@

$sequelize_seeds_user_content_express_ts = @'
    import { QueryInterface } from 'sequelize';

    export default {
        up: async (queryInterface: QueryInterface) => {
            const users = [
                {
                    name: 'John Doe',
                    email: 'john@example.com',
                    status: 'connected',
                    createdAt: new Date(),
                    updatedAt: new Date(),
                },
                {
                    name: 'Jane Smith',
                    email: 'jane@example.com',
                    status: 'disconnected',
                    createdAt: new Date(),
                    updatedAt: new Date(),
                },
            ];

            await queryInterface.bulkInsert('users', users, {});
        },

        down: async (queryInterface: QueryInterface) => {
            await queryInterface.bulkDelete('users', {}, {});
        },
    };
'@

$sequelize_configs_database_content_express_ts = @'
    import { config as env } from './env.ts';

    const databaseConfig = {
        development: {
            username: env.db.user,
            password: env.db.password,
            database: env.db.name,
            host: env.db.host,
            port: env.db.port,
            dialect: env.db.dialect,
        },
        test: {
            username: env.db.user,
            password: env.db.password,
            database: 'database_test',
            host: env.db.host,
            port: env.db.port,
            dialect: env.db.dialect,
            logging: false,
        },
        production: {
            username: env.db.user,
            password: env.db.password,
            database: 'database_prod',
            host: env.db.host,
            port: env.db.port,
            dialect: env.db.dialect,
            logging: false,
        },
    };

    export default databaseConfig;
'@
