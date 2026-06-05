$main_content_express_ts = @'
    import express, { type Request, type Response, Application } from 'express';
    import swaggerUi from 'swagger-ui-express';
    import YAML from 'yamljs';
    import path from 'path';
    import fs from 'fs';
    import cors from 'cors';
    import session from 'express-session';
    import cookieParser from 'cookie-parser';
    import { fileURLToPath } from 'url';
    import routes from './app/routes/index.ts';
    import basicAuth from 'express-basic-auth';
    import { config } from './configs/env.ts';
    import merge from 'lodash/merge.js';
    import { TokenCleanupService } from './app/services/TokenCleanupService.ts';

    const app: Application = express();

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    const docsDir = path.join(__dirname, 'docs');
    let swaggerDocument: any = {};

    const getYamlFilesRecursively = (dir: string): string[] => {
        let results: string[] = [];
        const list = fs.readdirSync(dir);

        list.forEach((file) => {
            const filePath = path.join(dir, file);
            const stat = fs.statSync(filePath);

            if (stat && stat.isDirectory()) {
                results = results.concat(getYamlFilesRecursively(filePath));
            } else if (file.endsWith('.yaml') || file.endsWith('.yml')) {
                results.push(filePath);
            }
        });

        return results;
    };

    if (fs.existsSync(docsDir)) {
        const allYamlFiles = getYamlFilesRecursively(docsDir);

        const mainFilePath = path.join(docsDir, 'main.yaml');
        if (fs.existsSync(mainFilePath)) {
            swaggerDocument = YAML.load(mainFilePath) || {};
        }

        allYamlFiles.forEach((filePath) => {
            if (filePath === mainFilePath) return;

            const fileContent = YAML.load(filePath);
            if (fileContent) {
                merge(swaggerDocument, fileContent);
            }
        });
    }

    app.use(
        cors({
            origin: true,
            allowedHeaders: ['Content-Type', 'Authorization'],
            methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
            preflightContinue: false,
            optionsSuccessStatus: 200,
            credentials: true,
        }),
    );

    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));
    app.use(cookieParser());

    app.use(
        session({
            secret: config.sessionSecret,
            resave: false,
            saveUninitialized: true,
            cookie: {
                secure: config.nodeEnv === 'production',
                httpOnly: true,
                maxAge: 24 * 60 * 60 * 1000, // 24 heures
            },
        }),
    );

    app.use(
        '/api-docs',
        basicAuth({
            users: { [config.swaggerUser]: config.swaggerPassword },
            challenge: true,
            realm: 'Swagger Docs',
        }),
        swaggerUi.serve,
        swaggerUi.setup(swaggerDocument),
    );

    app.get('/', (req: Request, res: Response) => {
        res.send({ message: 'Bienvenue sur ton API Express en TypeScript !' });
    });

    app.use('/api', routes);

    app.listen(config.port, () => {
        console.log(`Serveur : http://localhost:${config.port}`);
        console.log(`Documentation : http://localhost:${config.port}/api-docs`);
        TokenCleanupService.start();
    });
'@

$controller_user_content_express_ts = @'
    import type { Request, Response } from 'express';
    import { User } from '../repositories/UserRepository.ts';
    import { success, error } from '../services/ResponseService.ts';

    export class UserController {
        public async getAllUsers(_: Request, res: Response): Promise<void> {
            try {
                const users = await User.getAll();
                success(res, 200, 'Users retrieved successfully', users);
            } catch (err: any) {
                error(res, 500, 'Erreur serveur', { details: err.message });
            }
        }

        public async createUser(req: Request, res: Response) {
            try {
                const newUser = await User.create(req.body);
                success(res, 201, 'User created successfully', newUser);
            } catch (err: any) {
                error(res, 400, 'Bad Request', { details: err.message });
            }
        }
    }

    export const userController = new UserController();
'@

$service_response_content_express_ts = @'
    import type { Response } from 'express';

    interface ApiResponse<T = any> {
        success: boolean;
        status_code: number;
        message: string;
        data?: T;
        errors?: any;
        timestamp: string;
    }

    export const success = <T>(
        res: Response,
        status_code: number = 200,
        message: string = 'Success',
        data: T | null = null,
    ): Response => {
        const responseBody: ApiResponse<T> = {
            success: true,
            status_code,
            message,
            data: data as T,
            timestamp: new Date().toISOString(),
        };

        return res.status(status_code).json(responseBody);
    };

    export const error = (res: Response, status_code: number = 500, message: string = 'Internal Server Error', errors: any = null): Response => {
        const responseBody: ApiResponse = {
            success: false,
            status_code,
            message,
            errors,
            timestamp: new Date().toISOString(),
        };

        return res.status(status_code).json(responseBody);
    };
'@

$service_token_cleanup_content_express_ts = @'
    import cron from 'node-cron';
    import { Token } from '../repositories/UserRepository.ts';

    export class TokenCleanupService {
        static start() {
            cron.schedule('*/5 * * * *', async () => {
                console.log('[Background Job] Starting expired tokens cleanup...');

                try {
                    const now = new Date();
                    const deletedCount = await Token.deleteExpired(now);

                    console.log(`[Background Job] Cleanup successful. Removed ${deletedCount} expired tokens.`);
                } catch (err) {
                    console.error('[Background Job] Error during token cleanup:', err);
                }
            });

            console.log('Token Cleanup Service initialized (Running in background every 5 minutes).');
        }
    }
'@

$repository_base_content_express_ts = @'
    import { Model, type ModelStatic, type WhereOptions, type CreateOptions, type BulkCreateOptions, type UpdateOptions, type DestroyOptions, type FindOptions } from 'sequelize';

    export abstract class BaseRepository<T extends Model> {
        protected model: ModelStatic<T>;

        constructor(model: ModelStatic<T>) {
            this.model = model;
        }

        async getAll(options?: Omit<FindOptions<T['_attributes']>, 'where'>): Promise<T[]> {
            return await this.model.findAll({ ...options });
        }

        async findOne(whereClause: WhereOptions<T['_attributes']>, options?: Omit<FindOptions<T['_attributes']>, 'where'>): Promise<T | null> {
            return await this.model.findOne({
                ...options,
                where: whereClause,
            });
        }

        async findAll(whereClause: WhereOptions<T['_attributes']>, options?: Omit<FindOptions<T['_attributes']>, 'where'>): Promise<T[]> {
            return await this.model.findAll({
                ...options,
                where: whereClause,
            });
        }

        async findAndCountAll(whereClause: WhereOptions<T['_attributes']>, options?: Omit<FindOptions<T['_attributes']>, 'where'>): Promise<{ rows: T[]; count: number }> {
            const result = await this.model.findAndCountAll({ where: whereClause, ...options });
            return { rows: result.rows, count: result.count };
        }

        async create(data: any, options?: CreateOptions<T['_attributes']>): Promise<T> {
            return await this.model.create(data, options);
        }

        async bulkCreate(data: any[], options?: BulkCreateOptions<T['_attributes']>): Promise<T[]> {
            return await this.model.bulkCreate(data, options);
        }

        async update(data: Partial<T['_attributes']>, whereClause: WhereOptions<T['_attributes']>, options?: Omit<UpdateOptions<T['_attributes']>, 'where'>): Promise<number> {
            const [affectedCount] = await this.model.update(data, { ...options, where: whereClause });
            return affectedCount;
        }

        async destroy(whereClause: WhereOptions<T['_attributes']>, options?: Omit<DestroyOptions<T['_attributes']>, 'where'>): Promise<number> {
            return await this.model.destroy({ ...options, where: whereClause });
        }

        async count(whereClause: WhereOptions<T['_attributes']>, options?: Omit<FindOptions<T['_attributes']>, 'where'>) {
            return await this.model.count({ where: whereClause, ...options });
        }
    }
'@

$repository_user_content_express_ts = @'
    import { BaseRepository } from './BaseRepository.ts';
    import db from '../../database/models/index.ts';
    import { Op } from 'sequelize';

    type UserInstance = InstanceType<typeof db.User>;
    type TokenInstance = InstanceType<typeof db.Token>;

    class UserRepository extends BaseRepository<UserInstance> {
        constructor() {
            super(db.User);
        }
    }

    class TokenRepository extends BaseRepository<TokenInstance> {
        constructor() {
            super(db.Token);
        }

        async findUserToken(user_id: number, token_type: 'access' | 'refresh'): Promise<TokenInstance | null> {
            return await this.model.findOne({
                where: { user_id, token_type, token_status: 'active' },
            });
        }

        /**
         * Supprime tous les jetons dont la date d'expiration est dépassée
         * @param now Date actuelle
         * @returns Nombre de jetons supprimés
         */
        async deleteExpired(now: Date): Promise<number> {
            return await this.model.destroy({
                where: { expires_at: { [Op.lt]: now } },
            });
        }
    }

    export const User = new UserRepository();
    export const Token = new TokenRepository();
'@

$routes_user_content_express_ts = @'
    import { Router } from 'express';
    import { userController } from '../../controllers/UserController.ts';

    const router = Router();

    router.get('/find-all', userController.getAllUsers);
    router.post('/create', userController.createUser);

    export default router;
'@

$routes_index_content_express_ts = @'
    import { Router } from 'express';
    import v1UserRoutes from './v1/user.ts';

    const router = Router();

    router.use('/v1/user', v1UserRoutes);

    export default router;
'@


# =================================
# Jest (TESTS UNITAIRES)
# =================================
$jest_config_content_express_ts = @'
    const { createDefaultPreset } = require('ts-jest');

    const tsJestTransformCfg = createDefaultPreset().transform;

    /** @type {import('ts-jest').JestConfigWithTsJest} */
    module.exports = {
        preset: 'ts-jest/presets/default-esm',
        testEnvironment: 'node',

        extensionsToTreatAsEsm: ['.ts'],

        moduleNameMapper: {
            '^(\\.{1,2}/.*)\\.ts$': '$1',
        },

        transform: {
            '^.+\\.ts$': [
                'ts-jest',
                {
                    useESM: true,
                },
            ],
        },
    };
'@

$jest_index_content_express_ts = @'
    import express from 'express';
    import routes from '../app/routes/index.ts';

    const app = express();
    app.use(express.json());

    app.use('/api', routes);

    export default app;
'@

$jest_user_content_express_ts = @'
    import request from 'supertest';
    import app from './index.ts';
    import { sequelize } from '../database/models/index.ts';

    describe('User API Tests', () => {
        beforeAll(async () => {
            await sequelize.sync({ force: true });
        });

        afterAll(async () => {
            await sequelize.close();
        });

        describe('GET /api/v1/user/find-all', () => {
            it('doit retourner la liste des utilisateurs (200)', async () => {
                const response = await request(app).get('/api/v1/user/find-all');

                expect(response.statusCode).toBe(200);
                expect(Array.isArray(response.body.data)).toBe(true);

                if (response.body.data.length > 0) {
                    expect(response.body.data[0]).toHaveProperty('user_id');
                    expect(response.body.data[0]).toHaveProperty('name');
                    expect(response.body.data[0]).toHaveProperty('email');
                    expect(response.body.data[0]).toHaveProperty('status');
                }
            });
        });

        describe('POST /api/v1/user/create', () => {
            const uniqueEmail = `test${Date.now()}@example.com`;

            it('doit créer un utilisateur avec succès (201)', async () => {
                const newUser = {
                    name: 'Test User',
                    email: uniqueEmail,
                };

                const response = await request(app)
                    .post('/api/v1/user/create')
                    .send(newUser);

                expect(response.statusCode).toBe(201);
                expect(response.body.data).toHaveProperty('user_id');
                expect(response.body.data.name).toBe(newUser.name);
                expect(response.body.data.email).toBe(newUser.email);
            });

            it("doit échouer si l'email est déjà utilisé (400)", async () => {
                const duplicateUser = {
                    name: 'Autre Nom',
                    email: uniqueEmail,
                };

                const response = await request(app)
                    .post('/api/v1/user/create')
                    .send(duplicateUser);

                expect(response.statusCode).toBe(400);
                expect(response.body).toHaveProperty('errors');
            });

            it("doit échouer si le format de l'email est invalide (400)", async () => {
                const badUser = {
                    name: 'Bad Email',
                    email: 'pas-un-email',
                };

                const response = await request(app)
                    .post('/api/v1/user/create')
                    .send(badUser);

                expect(response.statusCode).toBe(400);
                expect(response.body).toHaveProperty('errors');
            });

            it('doit échouer si des champs requis sont manquants (400)', async () => {
                const incompleteUser = {
                    name: 'Incomplet',
                };

                const response = await request(app)
                    .post('/api/v1/user/create')
                    .send(incompleteUser);

                expect(response.statusCode).toBe(400);
                expect(response.body).toHaveProperty('errors');
            });
        });
    });
'@
