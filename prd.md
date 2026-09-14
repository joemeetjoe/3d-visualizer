3D Vehicle Damage Visualizer — Proof of Concept

Version: 1.0
Status: POC / Stakeholder Demo
Target: Production-quality UI, real data pipeline

1. Executive Summary

A browser-based system that allows an insurance adjuster to initiate a damage claim, send a unique capture link to a customer, and receive a photogrammetry-generated 3D model of the customer's vehicle. The adjuster reviews the model in an interactive 3D viewer, marks damage with pins, painted regions, and severity categories, and manages claims from a dashboard. No mobile app installation is required from the customer.

2. Goals & Non-Goals

Goals

Demonstrate a full end-to-end pipeline: claim creation → customer capture → 3D reconstruction → adjuster review
Use real photogrammetry data (not pre-made models) for stakeholder credibility
Production-quality UI suitable for executive presentation and potential productization
All AWS infrastructure, MIT-licensed open source dependencies only
Non-Goals (explicitly out of scope for POC)

Authentication / authorization (stubbed, to be added post-POC)
Customer PII storage (claim identified by UUID only)
SMS notifications (email only via SES)
Multi-language support
Claim cost estimation engine
Real-time adjuster/customer collaboration
Motorcycles, RVs, or specialty vehicles
3. Users & Roles

Role

Description

Entry Point

Adjuster

Insurance employee who creates claims, reviews 3D models, and marks damage

Adjuster dashboard (desktop browser)

Customer

Vehicle owner who photographs their car following guided steps

Unique claim link (mobile browser)

No login is required for either role in the POC. The adjuster accesses the dashboard directly. The customer receives a unique UUID-based URL.

4. System Architecture

[Adjuster Dashboard]

        │

        │  POST /claims  (creates claim, stores in RDS)

        ▼

[API Gateway → Lambda (TypeScript)]

        │

        │  Generates unique capture URL

        │  Sends email to adjuster with customer link (SES)

        ▼

[Customer opens unique URL on phone browser]

        │

        │  Guided photo capture flow (browser getUserMedia or file upload)

        │  20–40 photos uploaded via presigned S3 URL

        ▼

[S3 — raw-uploads bucket]

        │

        │  S3 Event Notification → Lambda orchestrator

        ▼

[Lambda Orchestrator]

        │

        │  Validates upload set complete

        │  Submits job to AWS Batch

        │  Updates claim status → "processing" in RDS

        ▼

[AWS Batch — EC2 GPU (g4dn.xlarge)]

        │

        │  Docker container: COLMAP + OpenMVS pipeline

        │  Input:  raw photos from S3

        │  Output: .glb mesh + texture files

        ▼

[S3 — processed-models bucket]

        │

        │  Lambda post-processor:

        │  - Updates claim status → "ready" in RDS

        │  - Sends adjuster email notification via SES

        ▼

[Adjuster opens claim in dashboard]

        │

        │  Fetches presigned .glb URL from S3

        │  Three.js renders model in browser

        │  Adjuster places pins, paints regions, sets severity

        │  Annotations saved → API Gateway → Lambda → RDS

        ▼

[RDS PostgreSQL — source of truth]

5. Infrastructure & Services

Service

Purpose

Notes

AWS S3 (2 buckets)

Raw photo uploads + processed .glb models

Lifecycle rules: raw photos expire after 30 days

AWS Lambda (TypeScript)

API handlers + orchestration

Node 20.x runtime

AWS Batch

GPU photogrammetry processing

g4dn.xlarge spot instance, Docker container

AWS ECR

Container registry for COLMAP/OpenMVS image

Built once, pulled by Batch

AWS RDS PostgreSQL

Claims, annotations, processing status

Deployed inside existing VPC

AWS API Gateway (HTTP)

REST API for frontend

Integrated with Lambda

AWS SES

Adjuster email notification

"Model ready" trigger only

AWS CloudFront

Frontend CDN + S3 static hosting

Serves the Vite/React bundle

AWS IAM

Scoped roles per service

Fits existing IAM structure

6. Frontend Architecture

Stack: Vite + React + TypeScript
3D Rendering: Three.js (MIT) with @react-three/fiber and @react-three/drei
Styling: Tailwind CSS
State Management: Zustand (lightweight, MIT)
HTTP Client: Axios
Routing: React Router v6

Application Entry Points

/                        → Adjuster Dashboard (claim list)

/claims/new              → Create new claim

/claims/:claimId         → Claim detail + 3D viewer

/capture/:claimToken     → Customer capture flow (mobile-optimized)

7. Feature Specifications

7.1 Adjuster Dashboard

Route: /

Description:
A clean, data-forward dashboard listing all active claims with their current pipeline status. Designed for desktop use.

Claim Statuses:

awaiting_capture — link sent, customer has not yet uploaded photos
uploading — customer is actively uploading
processing — AWS Batch job is running
ready — 3D model available for review
reviewed — adjuster has added annotations
closed — claim finalized
UI Elements:

Claim list table: Claim ID, Vehicle description, Status badge (color-coded), Created date, Last updated
Status badge micro-interaction: pulse animation on processing status
Filter bar: filter by status
"New Claim" CTA button (primary, top right)
Empty state: illustrated prompt to create first claim
Row hover reveals "Open Claim" action inline
Data:
Fetched from GET /claims — returns paginated claim list.

7.2 Create Claim

Route: /claims/new

Description:
Adjuster fills in minimal claim details. The system generates a unique customer capture link. Adjuster copies or shares the link to the customer (email/SMS handled externally — out of scope for POC).

Form Fields:

Vehicle Year (number input)
Vehicle Make (text input)
Vehicle Model (text input)
Vehicle Color (text input)
Adjuster notes (optional textarea)
Customer email address (used only to display the capture link — not stored as PII beyond the claim record)
On Submit:

POST /claims creates a claim record in RDS
Response returns { claimId, captureToken, captureUrl }
UI transitions to a "Claim Created" confirmation screen showing:
The unique capture URL (large, copyable)
A QR code the adjuster can show on screen or screenshot
"Send via SES" button (triggers a pre-templated email with the link)
"Go to Claim" button navigates to /claims/:claimId
Validation:

Year: 4-digit number, 1980–current year+1
Make/Model: required, max 50 chars each
All fields show inline validation on blur
7.3 Customer Capture Flow

Route: /capture/:claimToken
Device: Mobile browser (iOS Safari, Android Chrome)
Auth: None — token in URL is the only gate

Description:
A guided, step-by-step photo capture experience optimized for a phone held in portrait orientation. The customer is walked through 8 mandatory camera positions around the vehicle plus 4 optional close-up damage shots.

Capture Positions (mandatory — 8 shots):

Step

Position

Instruction Text

1

Front center

"Stand 6 feet in front of your vehicle. Center it in the frame."

2

Front-left corner

"Move to the front-left corner. Keep the whole vehicle visible."

3

Left side

"Stand at the middle of the left side, 8 feet away."

4

Rear-left corner

"Move to the rear-left corner."

5

Rear center

"Stand 6 feet behind your vehicle. Center it in the frame."

6

Rear-right corner

"Move to the rear-right corner."

7

Right side

"Stand at the middle of the right side, 8 feet away."

8

Front-right corner

"Move to the front-right corner."

Capture Positions (optional — up to 4 damage close-ups):

Customer can tap "Add damage photo" after completing mandatory shots
These are labeled damage_1 through damage_4 in S3
UX Flow per Step:

Full-screen instruction card with illustrated vehicle diagram highlighting the target position
Live camera viewfinder (via getUserMedia) with a vehicle silhouette overlay guide
Tap to capture — photo previewed in a thumbnail strip at bottom
Retake or confirm
Progress indicator: "3 of 8 positions captured"
Fallback (no camera access):
If getUserMedia is denied or unavailable, fall back to <input type="file" accept="image/*" capture="environment"> for each step.

Photo Quality Guidance:

Warn if image is blurry (check via canvas sharpness heuristic)
Warn if lighting appears very dark (check average pixel brightness)
Minimum resolution: 1920×1080 recommended, warn if below
Upload Behavior:

Each photo uploaded immediately after capture via presigned S3 URL (not batched at end)
Progress shown per photo: "Uploading 3 of 8..."
On all 8 mandatory photos uploaded: PATCH /claims/:claimId/status → uploading_complete
This triggers the Lambda orchestrator and Batch job
Completion Screen:

"You're done! Your insurer has been notified and will review your vehicle shortly."
No further action required from customer
7.4 3D Viewer & Damage Annotation

Route: /claims/:claimId
Device: Desktop browser

Description:
The core adjuster experience. A full-screen 3D viewer renders the photogrammetry-generated .glb model. The adjuster can orbit, zoom, and annotate damage directly on the mesh.

7.4.1 Viewer Controls

Control

Interaction

Orbit

Left-click drag

Pan

Right-click drag

Zoom

Scroll wheel

Reset camera

Double-click empty space

Focus on annotation

Click annotation pin

Touch equivalents for tablet use:

Orbit: 1-finger drag
Pan: 2-finger drag
Zoom: pinch
7.4.2 Annotation Tools (toolbar, left side)

Tool 1 — Damage Pin

Click anywhere on the mesh surface to place a 3D pin
Pin snaps to mesh surface using raycasting
On placement: inline popover opens with:
Note text field (free text)
Severity selector: Minor / Moderate / Severe / Total Loss
Pin renders as a 3D sphere with severity-coded color:
Minor: yellow
Moderate: orange
Severe: red
Total Loss: dark red / pulsing
Hover over pin: shows note preview tooltip
Click pin: opens edit popover
Right-click pin: delete with confirmation
Tool 2 — Paint Region

Activates brush mode
Click-drag on mesh surface paints a highlighted damage region
Region stored as a set of face indices on the mesh
Painted regions rendered as a semi-transparent overlay (red tint, adjustable opacity)
Brush size slider in toolbar when tool is active
Eraser mode toggle to remove painted areas
Tool 3 — Select / Orbit (default)

Returns to default orbit mode with no annotation active
7.4.3 Annotations Panel (right sidebar)

List of all placed pins with: severity badge, note preview, "Jump to" button
List of all painted regions with: area label (auto-named "Region 1", "Region 2", etc.), "Jump to" button
"Export Annotations" button → downloads JSON summary of all annotations
7.4.4 Model Loading States

Skeleton loader while .glb fetches
Progress bar for large model downloads
Error state if model fails to load (with retry)
If claim status is not ready: show status card ("Model is still processing — check back soon") instead of viewer
7.4.5 Saving

Annotations auto-save on every change (debounced 2 seconds)
"Saved" / "Saving..." indicator in top bar
Manual "Save" button as fallback
7.5 Claim Detail Header (above viewer)

Persistent across the claim detail page:

Vehicle: Year / Make / Model / Color
Claim ID (copyable)
Status badge
Created date
Adjuster notes (editable inline)
"Mark as Reviewed" button → sets status to reviewed
"Close Claim" button → sets status to closed (confirmation dialog)
8. Backend API Specification

Base URL: https://api.<domain>/v1
Runtime: Node.js 20 / TypeScript / AWS Lambda
Framework: Hono (lightweight, MIT, Lambda-optimized)

Endpoints

POST   /claims                         Create a new claim

GET    /claims                         List all claims (paginated)

GET    /claims/:claimId                Get claim detail

PATCH  /claims/:claimId/status         Update claim status

 

GET    /claims/:claimId/upload-urls    Get presigned S3 URLs for photo upload (returns array of 12 URLs)

POST   /claims/:claimId/upload-complete Notify upload complete, trigger Batch job

 

GET    /claims/:claimId/model-url      Get presigned S3 URL for .glb model

 

GET    /claims/:claimId/annotations    Get all annotations for a claim

PUT    /claims/:claimId/annotations    Replace full annotation set (upsert)

9. Database Schema (PostgreSQL)

-- Claims table

CREATE TABLE claims (

  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  capture_token UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),

  vehicle_year  SMALLINT NOT NULL,

  vehicle_make  VARCHAR(50) NOT NULL,

  vehicle_model VARCHAR(50) NOT NULL,

  vehicle_color VARCHAR(30),

  adjuster_notes TEXT,

  status        VARCHAR(30) NOT NULL DEFAULT 'awaiting_capture',

  s3_raw_prefix VARCHAR(255),

  s3_model_key  VARCHAR(255),

  batch_job_id  VARCHAR(255),

  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

 

-- Annotations table

CREATE TABLE annotations (

  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  claim_id    UUID NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

  type        VARCHAR(20) NOT NULL CHECK (type IN ('pin', 'region')),

  data        JSONB NOT NULL,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()

);

 

-- Indexes

CREATE INDEX idx_claims_status     ON claims(status);

CREATE INDEX idx_claims_capture_token ON claims(capture_token);

CREATE INDEX idx_annotations_claim ON annotations(claim_id);

Annotation JSONB shape — Pin:

{

  "position": { "x": 0.0, "y": 0.0, "z": 0.0 },

  "normal":   { "x": 0.0, "y": 1.0, "z": 0.0 },

  "severity": "moderate",

  "note":     "Rear quarter panel crease approx 18 inches"

}

Annotation JSONB shape — Region:

{

  "faceIndices": [1024, 1025, 1026, 1027],

  "label": "Region 1",

  "color": "#FF4444",

  "opacity": 0.4

}

10. Photogrammetry Pipeline

Container: COLMAP + OpenMVS

Base Image: Ubuntu 22.04
Tools:

COLMAP 3.8 (BSD license) — Structure from Motion (SfM): feature extraction, matching, sparse reconstruction
OpenMVS (AGPL — see license note below) — Dense reconstruction, mesh generation, texturing
⚠️ License Note: OpenMVS is licensed under AGPL v3, not MIT. For a POC this is acceptable as long as the container is internal and not distributed as a product. Before productizing, evaluate replacing OpenMVS with AliceVision/Meshroom (MPL 2.0) or a commercial alternative. Flag this for legal review before shipping.

Pipeline Steps (run inside Batch container):

1. COLMAP feature_extractor    → extracts SIFT features from all images

2. COLMAP exhaustive_matcher   → matches features across image pairs

3. COLMAP mapper               → sparse 3D reconstruction (SfM)

4. COLMAP image_undistorter    → prepares images for MVS

5. OpenMVS DensifyPointCloud   → dense point cloud from sparse

6. OpenMVS ReconstructMesh     → triangle mesh from point cloud

7. OpenMVS RefineMesh          → smooths and improves mesh

8. OpenMVS TextureMesh         → projects photo textures onto mesh

9. Convert output → .glb       → using Open3D or trimesh (MIT)

10. Upload .glb to S3          → processed-models bucket

11. Lambda callback            → update RDS status, trigger SES email

Estimated Processing Time: 3–8 minutes on g4dn.xlarge with 20–40 photos
Instance Type: g4dn.xlarge (4 vCPU, 16GB RAM, NVIDIA T4 GPU)
Cost Estimate: ~$0.16/job on spot pricing

11. Email Notification (SES)

Trigger: Lambda post-processor after .glb upload to S3
Recipient: Stored adjuster email on claim record
Subject: [ClaimID] Vehicle model ready for review
Body (plain text + HTML):

The 3D model for claim [ID] — [Year] [Make] [Model] — is ready for your review.

 

Open in viewer: https://<domain>/claims/<claimId>

SES Requirements:

SES domain/email must be verified in existing AWS account
Lambda execution role must have ses:SendEmail permission
12. S3 Bucket Configuration

<app>-raw-uploads

Versioning: disabled
Lifecycle: expire objects after 30 days
CORS: allow PUT from frontend domain (presigned URL uploads)
Block public access: enabled
Folder structure: claims/<claimId>/raw/<filename>
<app>-processed-models

Versioning: disabled
Lifecycle: transition to S3 Glacier after 365 days
Block public access: enabled (access via presigned URLs only)
Folder structure: claims/<claimId>/model/model.glb
13. UI Design Direction

Aesthetic: Precision tooling — the feel of professional software used in high-stakes environments. Think Figma meets aviation cockpit. Dark-mode first, clean data hierarchy, zero decorative noise.

Color Palette:

Background primary: #0F1117
Surface: #1A1D27
Surface elevated: #22263A
Accent (primary action): #4F8EF7 (electric blue — trust, technology)
Accent (damage / warning): #F7604F (damage red)
Text primary: #F0F2F8
Text secondary: #8B91A8
Status — processing: #F7C94F (amber, pulsing)
Status — ready: #4FCB8D (green)
Status — closed: #8B91A8 (muted)
Typography:

Display / headings: Inter (variable, tight tracking at large sizes)
Data / monospace (claim IDs, coordinates): JetBrains Mono
Body: Inter regular
Signature Element:
The 3D viewer occupies the full viewport with a floating glass-morphism toolbar and annotation sidebar. The model sits in a dark void with a subtle grid floor plane, ambient + directional lighting, and a soft vignette. Damage pins glow with a halo effect proportional to severity.

Motion:

Page transitions: 150ms fade
Status badge pulse: CSS keyframe, only on processing
Pin placement: spring pop animation on mount
Sidebar panels: slide in from right (200ms ease-out)
Hover states on all interactive elements: 100ms
Reduced motion: all animations disabled via prefers-reduced-motion
14. Build Phases

Phase 1 — Adjuster Viewer (Week 1–2)

Vite + React scaffold
Three.js viewer with a placeholder .glb car model
Damage pin placement (raycasting)
Paint region tool
Severity categories
Annotations sidebar
Auto-save to mock API
Deliverable: Fully interactive 3D viewer demo — showable to stakeholders independently

Phase 2 — Adjuster Dashboard + Claim Creation (Week 2–3)

Dashboard claim list
Create claim form
Claim detail page wrapping the viewer
PostgreSQL schema + RDS instance
API Gateway + Lambda (TypeScript) REST API
Status management
Deliverable: End-to-end adjuster flow with real database

Phase 3 — Customer Capture Flow (Week 3–4)

Mobile-optimized capture UI
getUserMedia integration
Guided 8-step flow with overlays
Presigned S3 upload
Upload complete notification to Lambda
Deliverable: Customer can photograph a car from their phone browser

Phase 4 — Photogrammetry Pipeline (Week 4–6)

Docker container: COLMAP + OpenMVS
ECR push + AWS Batch job definition
Lambda orchestrator (S3 trigger → Batch submit)
Lambda post-processor (Batch complete → S3 upload → RDS update → SES email)
End-to-end test with real vehicle photos
Deliverable: Full pipeline working — real photos → real 3D model → adjuster viewer

15. Open Questions / Decisions for Post-POC

Item

Note

Authentication

Cognito + JWT recommended; adjuster SSO via SAML if enterprise

OpenMVS AGPL license

Evaluate AliceVision/Meshroom (MPL 2.0) or commercial SaaS replacement

Customer PII

Decide data retention policy before production

Claim management dashboard

Full dashboard with reporting, history, metrics

Multi-vehicle support

Extend capture flow for trucks/SUVs (different silhouette overlays)

Model quality tuning

COLMAP/OpenMVS parameters need tuning per lighting/environment conditions

Cost at scale

Batch spot instance pricing + S3 storage cost model needed

Accessibility

WCAG 2.1 AA audit before production

16. Repository Structure (Recommended Monorepo)

/

├── apps/

│   ├── web/                  # Vite + React frontend

│   │   ├── src/

│   │   │   ├── pages/        # Route-level components

│   │   │   ├── components/   # Shared UI components

│   │   │   ├── viewer/       # Three.js / R3F viewer module

│   │   │   ├── capture/      # Customer capture flow module

│   │   │   ├── store/        # Zustand state

│   │   │   ├── api/          # Axios API client

│   │   │   └── types/        # Shared TypeScript types

│   └── api/                  # Hono + Lambda TypeScript API

│       ├── src/

│       │   ├── routes/       # API route handlers

│       │   ├── db/           # Postgres client + queries

│       │   ├── services/     # S3, SES, Batch service wrappers

│       │   └── types/        # Shared types

├── infra/                    # AWS CDK (TypeScript) IaC

│   ├── stacks/

│   │   ├── StorageStack.ts

│   │   ├── ApiStack.ts

│   │   ├── BatchStack.ts

│   │   └── FrontendStack.ts

├── pipeline/                 # Docker: COLMAP + OpenMVS

│   ├── Dockerfile

│   ├── entrypoint.sh

│   └── scripts/

│       ├── run_colmap.sh

│       ├── run_openmvs.sh

│       └── export_glb.py

└── packages/

    └── shared-types/         # Shared TypeScript interfaces (claim, annotation, etc.)

Document generated for internal POC planning. All architecture decisions subject to revision based on AWS account constraints and legal review of open source licenses.

 

This message (including any attachments) may contain confidential, proprietary, privileged and/or private information. The information is intended to be for the use of the individual or entity designated above. If you are not the intended recipient of this message, please notify the sender immediately, and delete the message and any attachments. Any disclosure, reproduction, distribution or other use of this message or any attachments by an individual or entity other than the intended recipient is prohibited.

TRVDiscDefault::1201
