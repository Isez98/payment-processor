# Makefile for AWS SAM build and GitHub release artifact


BUILD_DIR=.aws-sam/build
ZIP_FILE=build-artifact.zip
REPO_OWNER=isacc
REPO_NAME=payment-processor
GITHUB_TOKEN?=

.PHONY: release clean


release:
	@echo "Fetching latest release tag from GitHub..."
	@TAG_NAME=$$(curl -s -H "Authorization: token $(GITHUB_TOKEN)" \
	  https://api.github.com/repos/$(REPO_OWNER)/$(REPO_NAME)/releases/latest | jq -r '.tag_name // empty'); \
	if [ -z "$$TAG_NAME" ] || [ "$$TAG_NAME" = "null" ]; then TAG_NAME="v0.0.1"; fi; \
	RELEASE_NAME="Release $$TAG_NAME"; \
	sam build && \
	cd $(BUILD_DIR) && zip -r ../../$(ZIP_FILE) . && \
	curl -s -X POST \
	  -H "Authorization: token $(GITHUB_TOKEN)" \
	  -H "Accept: application/vnd.github+json" \
	  https://api.github.com/repos/$(REPO_OWNER)/$(REPO_NAME)/releases \
	  -d "{\"tag_name\": \"$$TAG_NAME\", \"name\": \"$$RELEASE_NAME\", \"body\": \"Automated release\", \"draft\": false, \"prerelease\": false}" > release.json && \
	jq -r '.upload_url' release.json | sed 's/{?name,label}//' > upload_url.txt && \
	curl -s -X POST \
	  -H "Authorization: token $(GITHUB_TOKEN)" \
	  -H "Content-Type: application/zip" \
	  "$$(cat upload_url.txt)?name=$(ZIP_FILE)" \
	  --data-binary @$(ZIP_FILE)

clean:
	rm -rf $(BUILD_DIR) $(ZIP_FILE) release.json upload_url.txt
