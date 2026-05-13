# Cloud Veterinary Booking System (Azure-Ready MVP)

This repository contains the starter structure for a cloud-based veterinary booking platform with:
- appointment booking
- home-visit veterinary workflow
- AI chatbot support logs/tracing
- secure pet health records and communication support

## Project Structure

- `backend/` - Node.js/Express API starter
- `database/` - SQL schema and migration-ready scripts
- `docs/` - architecture and feature notes

## Deploy on Azure

See [docs/azure-deployment.md](docs/azure-deployment.md) for App Service, Azure SQL Database, and Blob Storage (CLI steps, env vars, and packaging the `backend/` folder).

## Quick Start

1. Install dependencies:
   - `cd backend`
   - `npm install`
2. Start the API:
   - `npm run dev`
3. Create database objects:
   - Run `database/schema.sql` on Azure SQL or local SQL Server

## MVP Modules Included in Schema

- Users and role-based access (owner, vet, clinic staff, admin)
- Clinic and veterinarian profiles
- Pet profiles and medical records
- Clinic/home-visit appointments
- Home visit lifecycle tracking
- Chatbot sessions/messages
- Notifications and audit logs

## Suggested Next Steps

1. Wire up authentication with Azure AD B2C.
2. Add Prisma or TypeORM models matching `database/schema.sql`.
3. Implement booking APIs and availability logic.
4. Integrate Azure OpenAI for chatbot responses with safety guardrails.
5. Add Azure Blob Storage for uploads (lab reports, prescriptions, media).
