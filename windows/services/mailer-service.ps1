$mailer_service_content_express_ts = @'
    import nodemailer from 'nodemailer';
    import ejs from 'ejs';
    import path from 'path';
    import { fileURLToPath } from 'url';
    import { config } from '../../configs/env.ts';

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    interface SendEmailOptions {
        to: string;
        subject: string;
        template: string;
        variables?: Record<string, any>;
        attachments?: nodemailer.SendMailOptions['attachments']; 
    }

    export class EmailService {
        private static createTransporter(): nodemailer.Transporter {
            return nodemailer.createTransport({
                host: config.smtp.host,
                port: Number(config.smtp.port) || 587,
                secure: config.smtp.secure === 'true',
                auth: {
                    user: config.smtp.user,
                    pass: config.smtp.pass,
                },
            });
        }

        static async sendEmailTemplate({ to, subject, template, variables = {}, attachments }: SendEmailOptions): Promise<any> {
            const transporter = EmailService.createTransporter();

            const templatePath = path.join(__dirname, '..', '..', 'templates', `${template}.ejs`);

            try {
                const html = await ejs.renderFile(templatePath, {
                    ...variables,
                    subject,
                });

                const mailOptions: nodemailer.SendMailOptions = {
                    from: config.smtp.from || config.smtp.user,
                    to,
                    subject,
                    html,
                    attachments,
                };

                const info = await transporter.sendMail(mailOptions);
                return { isSent: true, info };
            } catch (err) {
                throw { isSent: false, err };
            }
        }
    }
'@

$welcome_content_express_ejs = @"
<!DOCTYPE html>

<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= subject %></title>
    </head>
    <body>
        <h1>Welcome, <%= name %>!</h1>
        <p>Thank you for signing up. We're excited to have you on board!</p>
        <p>If you have any questions, feel free to reach out to our support team.</p>
        <p>Best regards,<br>The Team</p>
    </body>
</html>
"@

$mailer_config_content_express_ts = @'
    smtp: {
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: Number(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE || 'false',
        user: process.env.SMTP_USER || 'user-email@example.com',
        pass: process.env.SMTP_PASS,
        from: process.env.SMTP_FROM || 'Your App Name <user-email@example.com>',
    },
'@


function install-mailer-service-express {
    if (-Not (Test-Path "package.json")) {
        Write-Host "`n--- package.json not found. Run this inside a Node.js project. ---" -ForegroundColor red
        return
    }

    Write-Host "`n--- Installing dependencies (Production) ---" -ForegroundColor Cyan
    npm install nodemailer ejs

    Write-Host "`n--- Installing dependencies (Development) ---" -ForegroundColor Cyan
    npm install @types/nodemailer @types/ejs
    
    $dirs = @(
        "app/services",
        "templates"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/MailerService.ts" -Value $mailer_service_content_express_ts -Encoding UTF8
    Set-Content "templates/welcome.ejs" -Value $welcome_content_express_ejs -Encoding UTF8
    
    $files = @(".env", ".env.example")
    $auth_vars = @{
        "SMTP_HOST"   = "smtp.gmail.com";
        "SMTP_PORT"   = "587";
        "SMTP_SECURE" = "false";
        "SMTP_USER"   = "user-email@example.com";
        "SMTP_PASS"   = "your-email-password";
        "SMTP_FROM"   = "Your App Name <user-email@example.com>"
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

        if ($content -notmatch "smtp:") {
            $updatedContent = $content -replace "(?m)(?=db:\s*\{)", "$mailer_config_content_express_ts`n"
            Set-Content -Path $filePath -Value $updatedContent -NoNewline
            Write-Host "-> mailer configuration added to configs/env.ts" -ForegroundColor Gray
        }
    } else {
        Write-Host "-> configs/env.ts not found, configuration unchanged." -ForegroundColor Yellow
    }

    Write-Host "`n--- Formatting project code... ---" -ForegroundColor Green
    npm run format --silent

    if (Test-Path ".git") {
        Write-Host ""
        $GIT = Read-Host "Would you like to add a new commit to Git? (y/N)"
        
        if ($null -ne $GIT -and $GIT.Trim() -match '^[Yy]') {
            git add . | Out-Null
            git commit -m "feat: add mailer service with Nodemailer and EJS" | Out-Null
            Write-Host "-> Changes committed to Git." -ForegroundColor Gray
        }
    }

    Write-Host "`n--- Mailer Service installed successfully. ---" -ForegroundColor Green
}
