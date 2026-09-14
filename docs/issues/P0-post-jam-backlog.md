# P0 — Post-jam backlog (production path)

Everything cut for the 24h build, kept visible so the presentation can point at it honestly. Add to this file whenever you make a "demo-first" trade-off.

## Infrastructure (PRD §4, §5, §12, §16)
- [ ] AWS CDK stacks: Storage (S3 raw-uploads + processed-models with lifecycle rules), Api (API Gateway HTTP + Lambda), Batch (GPU compute env, job definition, ECR image), Frontend (CloudFront + S3)
- [ ] Presigned S3 PUT URLs replacing `/capture/:token/photos/:key` (the `UploadTarget` shape is already S3-compatible)
- [ ] S3 event → Lambda orchestrator → AWS Batch submit (replaces the in-process dispatcher)
- [ ] RDS PostgreSQL in the VPC (schema unchanged)
- [ ] SES "model ready" email (needs production access request + verified domain)
- [ ] IAM roles per service

## Product
- [ ] Authentication (Cognito + JWT; SAML SSO for adjusters)
- [ ] Paint region tool (if A5 not shipped)
- [ ] Pagination on `GET /claims`
- [ ] PII/data retention policy for customer email + photos
- [ ] Multi-vehicle silhouettes (truck/SUV)
- [ ] WCAG 2.1 AA audit
- [ ] Claim cost estimation hooks (annotation export is the interface)

## Pipeline
- [ ] License decision: Meshroom/AliceVision (MPL-2.0) vs OpenMVS (AGPL-3.0) — legal review before productizing
- [ ] Parameter tuning per lighting condition; background masking; multi-height capture guidance
- [ ] Evaluate feed-forward reconstruction (VGGT-1B-Commercial, MASt3R) for seconds-scale previews
- [ ] Cost model at scale (Batch spot vs on-demand; storage)

## Engineering hygiene
- [ ] Tests beyond the status-machine table test
- [ ] Error tracking, structured logs, metrics
- [ ] CI: typecheck + lint + build
