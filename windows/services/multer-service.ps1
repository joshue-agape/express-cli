$multer_service_express_ts = @'
    import multer from 'multer';
    import path from 'path';
    import fs from 'fs';
    import { fileURLToPath } from 'url';
    import { type Request } from 'express';

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    export class UploadService {
        private static uploadDir = path.join(__dirname, '..', '..', 'uploads');

        private static configureStorage(subFolder: string = '') {
            const finalDir = path.join(this.uploadDir, subFolder);

            if (!fs.existsSync(finalDir)) {
                fs.mkdirSync(finalDir, { recursive: true });
            }

            return multer.diskStorage({
                destination: (req, file, cb) => {
                    cb(null, finalDir);
                },
                filename: (req, file, cb) => {
                    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
                    const extension = path.extname(file.originalname);
                    const baseName = path.basename(file.originalname, extension).replace(/\s+/g, '_');

                    cb(null, `${baseName}-${uniqueSuffix}${extension}`);
                },
            });
        }

        private static createFileFilter(allowedTypes: RegExp) {
            return (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
                const extension = path.extname(file.originalname).toLowerCase();
                const isExtValid = allowedTypes.test(extension);

                const isMimeValid =
                    allowedTypes.test(file.mimetype) ||
                    file.mimetype.includes('wordprocessingml') ||
                    file.mimetype.includes('msword');

                if (isMimeValid && isExtValid) {
                    cb(null, true);
                } else {
                    cb(new Error(`Format de fichier non supporté. Types autorisés : ${allowedTypes}`));
                }
            };
        }

        public static createUploader({
            subFolder = '',
            allowedTypes = /jpeg|jpg|png|gif|pdf|docx/,
            maxSizeInMb = 5,
        }: {
            subFolder?: string;
            allowedTypes?: RegExp;
            maxSizeInMb?: number;
        } = {}) {
            return multer({
                storage: this.configureStorage(subFolder),
                limits: {
                    fileSize: maxSizeInMb * 1024 * 1024,
                },
                fileFilter: this.createFileFilter(allowedTypes),
            });
        }
    }
'@

$routes_multer_express_ts = @'
    import { Router, type Request, type Response, type NextFunction } from 'express';
    import { UploadService } from '../../services/UploadService.ts';

    const router = Router();

    const avatarUpload = UploadService.createUploader({
        subFolder: 'avatars',
        allowedTypes: /jpeg|jpg|png/,
        maxSizeInMb: 2,
    });

    router.post('/upload/avatar', avatarUpload.single('avatar'), (req: Request, res: Response) => {
        if (!req.file) {
            return res.status(400).json({ message: 'Veuillez sélectionner un fichier.' });
        }

        res.status(200).json({
            message: 'Avatar téléversé avec succès !',
            fileInfo: {
                filename: req.file.filename,
                path: req.file.path,
                size: req.file.size,
            },
        });
    });

    const documentUpload = UploadService.createUploader({
        subFolder: 'documents',
        allowedTypes: /pdf|docx/,
        maxSizeInMb: 10,
    });

    router.post('/upload/documents', documentUpload.array('documents', 3), (req: Request, res: Response) => {
        const files = req.files as Express.Multer.File[];

        if (!files || files.length === 0) {
            return res.status(400).json({ message: 'Aucun fichier reçu.' });
        }

        res.status(200).json({
            message: 'Documents sauvegardés.',
            files: files.map((f) => f.filename),
        });
    });

    export default router;
'@


function install-multer-service-express {
    if (-Not (Test-Path "package.json")) {
        Write-Host "`n--- package.json not found. Run this inside a Node.js project. ---" -ForegroundColor red
        return
    }

    Write-Host "`n--- Installing dependencies (Production) ---" -ForegroundColor Cyan
    npm install multer
    
    Write-Host "`n--- Installing dependencies (Development) ---" -ForegroundColor Cyan
    npm install -D @types/multer

    Set-Content "app/services/UploadService.ts" -Value $multer_service_express_ts -Encoding UTF8
    Set-Content "app/routes/v1/upload.ts" -Value $routes_multer_express_ts -Encoding UTF8

    $routerFilePath = "app/routes/index.ts"

    if (Test-Path $routerFilePath) {
        $routerContent = Get-Content -Raw -Path $routerFilePath

        if ($routerContent -notmatch "v1UploadRoutes") {
            
            if ($routerContent -match "(?s)(.*^import\s+[^`n]*\r?\n)(.*)") {
                $routerContent = $matches[1] + "import v1UploadRoutes from './v1/upload.ts';`r`n" + $matches[2]
            }

            if ($routerContent -match "(?s)(.*)(\r?\nexport\s+default\s+router;?)") {
                $routerContent = $matches[1] + "router.use('/v1/multer', v1UploadRoutes);`r`n`r`n" + $matches[2].TrimStart()
            } else {
                $routerContent = $routerContent -replace "(export\s+default)", "router.use('/v1/multer', v1UploadRoutes);`r`n`r`n`$1"
            }

            Set-Content -Path $routerFilePath -Value $routerContent -NoNewline
            Write-Host "-> Routes updated successfully according to your layout in $routerFilePath" -ForegroundColor Gray
        } else {
            Write-Host "-> Upload routes already present in $routerFilePath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "-> $routerFilePath not found, routing step skipped." -ForegroundColor Yellow
    }
    
    Write-Host "`n--- Formatting project code... ---" -ForegroundColor Green
    npm run format --silent

    if (Test-Path ".git") {
        Write-Host ""
        $GIT = Read-Host "Would you like to add a new commit to Git? (y/N)"
        
        if ($null -ne $GIT -and $GIT.Trim() -match '^[Yy]') {
            git add . | Out-Null
            git commit -m "feat: add multer service with Multer and Express" | Out-Null
            Write-Host "-> Changes committed to Git." -ForegroundColor Gray
        }
    }

    Write-Host "`n--- Multer Service installed successfully. ---" -ForegroundColor Green
}