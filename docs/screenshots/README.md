Screenshots folder for Doc_Ohpp delivery

Place verified screenshots here using the exact filenames below. The top-level README references these paths, so keep the filenames unchanged when you replace the placeholders.

Expected filenames (drop-in replacements):
- codebuild-success.png
- pipeline-success-screenshot.png
- pipeline-stage-details.png
- codebuild-success.png
- xray-traces.png
- app-health.png
- stepfunctions-execution.png

Guidelines
- Use PNG format.
- Recommended max file size: 2–5 MB per image.
- Filenames must match exactly (case-sensitive on some systems).

How to add screenshots (PowerShell)
1) Copy or save your screenshot into this folder (example):
   Copy-Item -Path "C:\Path\To\Your\image.png" -Destination ".\docs\screenshots\pipeline-success-screenshot.png" -Force
2) Stage, commit and push:
   git -C "C:\Users\Benny\DEVjensen\Doc_Ohpp" add docs\screenshots\pipeline-success-screenshot.png
   git -C "C:\Users\Benny\DEVjensen\Doc_Ohpp" commit -m "docs: add pipeline success screenshot"
   git -C "C:\Users\Benny\DEVjensen\Doc_Ohpp" push origin main

How to add screenshots (cmd.exe)
1) Copy or save your screenshot into this folder (example):
   copy /Y "C:\Path\To\Your\image.png" "docs\screenshots\pipeline-success-screenshot.png"
2) Stage, commit and push:
   cd /d C:\Users\Benny\DEVjensen\Doc_Ohpp
   git add docs\screenshots\pipeline-success-screenshot.png
   git commit -m "docs: add pipeline success screenshot"
   git push origin main

Notes
- Do NOT include absolute or local OneDrive links inside this README; they are not portable and won't render for other collaborators.
- If you'd like, I can commit screenshots for you — upload them here and I'll add/commit/push.
