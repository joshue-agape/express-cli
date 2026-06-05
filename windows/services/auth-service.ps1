$auth_service_content_express_ts = @'
    import bcrypt from 'bcrypt';
    import { randomBytes } from 'crypto';
    import type { Request } from 'express';
    import { UAParser } from 'ua-parser-js';
    import jwt, { type SignOptions, type JwtPayload, type Secret } from 'jsonwebtoken';
    import { config } from '../../configs/env.ts';

    /**
     * Extraction de la clé secrète depuis la configuration de l'application.
     * Cette clé est indispensable pour signer et vérifier l'intégrité des tokens JWT.
     */
    const CLIENT_SECRET = config.clientSecret;

    /**
     * Bloc de sécurité critique : bloque le démarrage de l'application si la clé de sécurité
     * d'authentification n'a pas pu être chargée depuis les variables d'environnement.
     */
    if (!CLIENT_SECRET) {
        throw new Error('FATAL ERROR: CLIENT_SECRET is not defined in configuration.');
    }

    /**
     * Génère une chaîne de caractères aléatoire (généralement utilisée pour les tokens de réinitialisation,
     * les codes d'activation ou les secrets à usage unique).
     * * @param byte Le nombre d'octets de données pseudo-aléatoires à générer (défaut: 32)
     * @returns Une chaîne de caractères sécurisée au format hexadécimal
     */
    export const generateToken = (byte: number = 32): string => {
        return randomBytes(byte).toString('hex');
    };

    /**
     * Hache le mot de passe avec un "salt" de 10 rounds.
     * * @param password Le mot de passe en clair à sécuriser
     * @param saltRounds Nombre de rounds pour le sel (défaut: 10)
     * @returns Le mot de passe haché de manière sécurisée sous forme de promesse
     */
    export const hashPassword = async (password: string, saltRounds: number = 10): Promise<string> => {
        if (!password || typeof password !== 'string') {
            throw new Error('Cannot hash password: password must be a non-empty string.');
        }

        return await bcrypt.hash(password, saltRounds);
    };

    /**
     * Compare un mot de passe en clair avec un mot de passe haché.
     * * @param password Le mot de passe saisi par l'utilisateur lors de la tentative de connexion
     * @param password_hashed Le hash du mot de passe stocké au préalable en base de données
     * @returns Un booléen confirmant si le mot de passe correspond ou non
     */
    export const isMatch = async (password: string, password_hashed: string): Promise<boolean> => {
        return await bcrypt.compare(password, password_hashed);
    };

    /**
     * Génère un token JWT pour un utilisateur.
     * * @param payload Données de l'utilisateur à embarquer de manière sécurisée dans le token
     * @param expiresIn Durée de validité avant expiration (défaut: '1d' pour 1 jour)
     * @param client_secret Clé secrète à utiliser pour la signature cryptographique (défaut: CLIENT_SECRET)
     * @returns Le token JWT encodé sous forme de chaîne de caractères
     */
    export const generateAuthToken = (payload: object, expiresIn: SignOptions['expiresIn'] = '1d', client_secret: Secret = CLIENT_SECRET): string => {
        return jwt.sign(payload, client_secret, {
            expiresIn: expiresIn,
        });
    };

    /**
     * Vérifie la validité d'un token JWT.
     * * @param token Le token JWT reçu à analyser et décoder
     * @param client_secret Clé secrète utilisée pour valider la signature (défaut: CLIENT_SECRET)
     * @returns Le payload décodé (objet) si le token est valide, ou null s'il a expiré / a été modifié
     */
    export const verifyToken = (token: string, client_secret: Secret = CLIENT_SECRET): JwtPayload | null => {
        try {
            const decoded = jwt.verify(token, client_secret);
            return decoded as JwtPayload;
        } catch (error) {
            return null;
        }
    };

    /**
     * Extrait et analyse les informations de l'appareil de l'utilisateur ainsi que son adresse IP
     * à partir des en-têtes d'une requête HTTP Express.
     * * @param req La requête HTTP entrante émise par Express
     * @returns Un objet contenant les détails lisibles du navigateur, du système d'exploitation et de l'IP
     */
    export const getDeviceDetails = (req: Request) => {
        const ip = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || '';

        const userAgentString = req.headers['user-agent'] || '';
        const parser = new UAParser(userAgentString);
        const result = parser.getResult();

        const browserName = result.browser.name || 'Unknown Browser';
        const browserVersion = result.browser.version || '';
        const osName = result.os.name || 'Unknown OS';
        const osVersion = result.os.version || '';

        const deviceDetails = `${browserName} ${browserVersion}`.trim() + ` / ${osName} ${osVersion}`.trim();

        return {
            device: deviceDetails,
            ip: ip,
        };
    };
'@

$auth_middleware_content_express_js = @'
    import jwt from 'jsonwebtoken';
    import type { Request, Response, NextFunction } from 'express';
    import { error } from '../services/ResponseService.ts';
    import { config } from '../../configs/env.ts';

    type JwtDecoded = { id: number; iat: number; exp: number };

    export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
        try {
            const authHeader = req.headers.authorization;

            if (!authHeader) {
                return error(res, 401, 'Authorization header is missing', {
                    code: 'AUTH_HEADER_MISSING',
                });
            }

            if (!authHeader.startsWith('Bearer ')) {
                return error(res, 401, 'Invalid authorization format', {
                    code: 'INVALID_AUTH_FORMAT',
                });
            }

            const token = authHeader.split(' ')[1];

            if(!token) {
                return error(res, 401, 'Token is missing', {
                    code: 'TOKEN_MISSING',
                });         
            }

            if (!config.clientSecret) {
                return error(res, 500, 'Internal server configuration error', {
                    code: 'MISSING_SECRET_KEY',
                });
            }

            const decoded = jwt.verify(token, config.clientSecret) as unknown as JwtDecoded;

            if (!decoded || !decoded.id) {
                return error(res, 403, 'Invalid token payload', {
                    code: 'INVALID_TOKEN_PAYLOAD',
                });
            }

            req.user = { user_id: decoded.id };
            next();
        } catch {
            return error(res, 403, 'Authentication failed', { code: 'AUTH_FAILED' });
        }
    };
'@

$declaration_type = @'
    import { JwtPayload } from 'jsonwebtoken';

    interface User {
        user_id: number;
    }

    declare global {
        namespace Express {
            interface Request {
                user: User;
            }
        }
    }

    declare module 'lodash.merge';
'@  

function install-auth-service-express {
    if (-Not (Test-Path "package.json")) {
        Write-Host "`n--- package.json not found. Run this inside a Node.js project. ---" -ForegroundColor red
        return
    }

    Write-Host "`n--- Installing dependencies (Production) ---" -ForegroundColor Cyan
    npm install bcrypt jsonwebtoken uuid ua-parser-js

    Write-Host "`n--- Installing dependencies (Development) ---" -ForegroundColor Cyan
    npm install -D @types/bcrypt @types/jsonwebtoken @types/uuid @types/ua-parser-js
    
    $dirs = @(
        "app/services",
        "app/middlewares",
        "app/types"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/AuthService.ts" -Value $auth_service_content_express_ts -Encoding UTF8
    Set-Content "app/middlewares/AuthMiddleware.ts" -Value $auth_middleware_content_express_js -Encoding UTF8
    Set-Content "app/types/express.d.ts" -Value $declaration_type -Encoding UTF8

    $files = @(".env", ".env.example")
    $auth_vars = @{
        "CLIENT_SECRET" = "client-secret-key-change-me"
    }

    foreach ($file in $files) {
        if (-Not (Test-Path $file)) {
            New-Item -ItemType File -Path $file | Out-Null
        }

        $content = Get-Content $file -Raw

        foreach ($key in $auth_vars.Keys) {
            if ($content -notmatch "(?m)^$key=") {
                Add-Content -Path $file -Value "$key='$($auth_vars[$key])'"
            }
        }
    }

    $filePath = "configs/env.ts"
    
    if (Test-Path $filePath) {
        $content = Get-Content -Raw -Path $filePath
        $newLine = "clientSecret: process.env.CLIENT_SECRET || 'your-default-secret',"

        if ($content -notmatch "clientSecret:") {
            $updatedContent = $content -replace "(?m)(?=db:\s*\{)", $newLine
            Set-Content -Path $filePath -Value $updatedContent -NoNewline
            Write-Host "-> clientSecret added to configs/env.ts" -ForegroundColor Gray
        }
    } else {
        Write-Host "-> configs/env.ts not found, configuration unchanged." -ForegroundColor Yellow
    }

    Write-Host "`n--- Formatting project code... ---" -ForegroundColor Green
    npm run format

    if (Test-Path ".git") {
        Write-Host ""
        $GIT = Read-Host "Would you like to add a new commit to Git? (y/N)"
        
        if ($null -ne $GIT -and $GIT.Trim() -match '^[Yy]') {
            git add . | Out-Null
            git commit -m "feat: add authentication service with JWT and bcrypt" | Out-Null
            Write-Host "-> Changes committed to Git." -ForegroundColor Gray
        }
    }

    Write-Host "`n--- Auth Service installed successfully. ---" -ForegroundColor Green
}