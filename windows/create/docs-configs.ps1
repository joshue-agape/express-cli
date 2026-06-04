$docs_main_yaml_content_express_ts = @'
openapi: 3.0.3
info:
    title: Mon API Express TypeScript
    version: 1.0.0
    description: Documentation de mon API avec Swagger et YAML.
    contact:
        name: API Support Team
        email: api-support@example.com

servers:
    - url: http://localhost:3000
      description: Local Development Server
    - url: https://api.stockmanagery.com
      description: Production Server

components:
    securitySchemes:
        BearerAuth:
            type: http
            scheme: bearer
            bearerFormat: JWT
            description: Entrez le jeton d'accès de votre application (access) pour accéder aux points de terminaison protégés.
'@

$docs_create_user_yaml_content_express_ts = @'
paths:
    /api/v1/user/create:
        post:
            summary: Enregistrer un nouvel utilisateur
            description: |
                Enregistre et sauvegarde directement un nouvel utilisateur dans la base de données avec un statut par défaut réglé sur `disconnected`.
            tags:
                - User Management
            requestBody:
                required: true
                content:
                    application/json:
                        schema:
                            type: object
                            required:
                                - name
                                - email
                            properties:
                                name:
                                    type: string
                                    description: Le nom complet de l'utilisateur.
                                    example: 'Joshué Agapé'
                                email:
                                    type: string
                                    format: email
                                    description: L'adresse e-mail unique de l'utilisateur.
                                    example: 'joshue.agape@example.com'
            responses:
                '201':
                    description: Utilisateur enregistré avec succès.
                    content:
                        application/json:
                            schema:
                                type: object
                                properties:
                                    success:
                                        type: boolean
                                        example: true
                                    status_code:
                                        type: integer
                                        example: 201
                                    message:
                                        type: string
                                        example: 'User created successfully'
                                    data:
                                        type: object
                                        properties:
                                            user_id:
                                                type: integer
                                                example: 1
                                            name:
                                                type: string
                                                example: 'Joshué Agapé'
                                            email:
                                                type: string
                                                example: 'joshue.agape@example.com'
                                            status:
                                                type: string
                                                enum: [connected, disconnected]
                                                example: 'disconnected'
                                            createdAt:
                                                type: string
                                                format: date-time
                                                example: '2026-06-04T02:47:20.000Z'
                                            updatedAt:
                                                type: string
                                                format: date-time
                                                example: '2026-06-04T02:47:20.000Z'
                                    timestamp:
                                        type: string
                                        format: date-time
                                        example: '2026-06-04T02:47:20.000Z'
                '400':
                    description: Requête incorrecte (Bad Request). Se produit si des champs obligatoires manquent, si le format de l'e-mail est invalide ou si l'e-mail existe déjà.
                    content:
                        application/json:
                            schema:
                                type: object
                                properties:
                                    success:
                                        type: boolean
                                        example: false
                                    status_code:
                                        type: integer
                                        example: 400
                                    message:
                                        type: string
                                        example: 'Bad Request'
                                    errors:
                                        type: object
                                        properties:
                                            details:
                                                type: string
                                                example: 'Validation error: Validation isEmail on email failed'
                                    timestamp:
                                        type: string
                                        format: date-time
                                        example: '2026-06-04T02:47:20.000Z'
'@

$docs_find_all_users_yaml_content_express_ts = @'
paths:
    /api/v1/user/find-all:
        get:
            summary: Récupérer la liste de tous les utilisateurs
            description: |
                Renvoie la liste complète de tous les utilisateurs enregistrés dans la base de données.
            tags:
                - User Management
            responses:
                '200':
                    description: Liste des utilisateurs récupérée avec succès.
                    content:
                        application/json:
                            schema:
                                type: object
                                properties:
                                    success:
                                        type: boolean
                                        example: true
                                    status_code:
                                        type: integer
                                        example: 200
                                    message:
                                        type: string
                                        example: 'Users retrieved successfully'
                                    data:
                                        type: array
                                        description: Tableau contenant la liste des utilisateurs.
                                        items:
                                            type: object
                                            properties:
                                                user_id:
                                                    type: integer
                                                    example: 1
                                                name:
                                                    type: string
                                                    example: 'Joshué Agapé'
                                                email:
                                                    type: string
                                                    example: 'joshue.agape@example.com'
                                                status:
                                                    type: string
                                                    enum:
                                                        [
                                                            connected,
                                                            disconnected,
                                                        ]
                                                    example: 'disconnected'
                                                createdAt:
                                                    type: string
                                                    format: date-time
                                                    example: '2026-06-04T02:47:20.000Z'
                                                updatedAt:
                                                    type: string
                                                    format: date-time
                                                    example: '2026-06-04T02:47:20.000Z'
                                    timestamp:
                                        type: string
                                        format: date-time
                                        example: '2026-06-04T02:52:00.000Z'
                '500':
                    description: Erreur interne du serveur.
                    content:
                        application/json:
                            schema:
                                type: object
                                properties:
                                    success:
                                        type: boolean
                                        example: false
                                    status_code:
                                        type: integer
                                        example: 500
                                    message:
                                        type: string
                                        example: 'Erreur serveur'
                                    errors:
                                        type: object
                                        properties:
                                            details:
                                                type: string
                                                example: "Formulation de l'erreur renvoyée par la base de données ou le système."
                                    timestamp:
                                        type: string
                                        format: date-time
                                        example: '2026-06-04T02:52:00.000Z'
'@