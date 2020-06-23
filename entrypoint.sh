# Determine VERSION
if [ -n "$INPUT_VERSION" ]
then
  VERSION=$INPUT_VERSION &&
    echo "INPUT_VERSION detected..."
elif [ -f ./package.json ]
then
  # "version": "0.1.0"
  VERSION=$(cat package.json | jq -r .version) &&
    echo "Node detected..."
elif [ -f  ./lib/*/version.rb ]
then
  # VERSION = '0.1.0'
  VERSION=$(cat ./lib/*/version.rb | grep -oP "(?<=VERSION).*" | cut -d \' -f2 | cut -d \" -f2 &&
    echo "Ruby detected..."
elif [ -f ./Dockerfile ]
then
  # LABEL version="0.1.0"
  VERSION=$(cat ./Dockerfile | grep -oP "(?<=version).*" | cut -d \' -f2 | cut -d \" -f2) &&
    echo "Dockerfile detected..."
else
  echo "VERSION unable to be detected..."
  echo "Set INPUT_VERSION, or submit a PR to support your language/framework!"
  echo "Exiting."
  exit 1
fi
GIT_TAG_NAME=${INPUT_GIT_TAG_PREFIX}${VERSION}
echo "Tag detected: ${GIT_TAG_NAME}"

# Check tag on GitHub
GET_API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/git/ref/tags/${GIT_TAG_NAME}"
echo "Checking for tag on GitHub..."
HTTP_STATUS_CODE=$(curl -LI $GET_API_URL -o /dev/null -w '%{http_code}\n' -s \
  -H "Authorization: token ${GITHUB_TOKEN}")
echo "GitHub returned with a ${HTTP_STATUS_CODE}."

# Exit if tag exists
if [ "$HTTP_STATUS_CODE" -e "404" ]
then
  echo "Tag does NOT exist. You may continue!"
elif [ "$HTTP_STATUS_CODE" -e "200" ]
then
  echo "Tag already exists.\nExiting."
  exit 1
else
  echo "Tag unable to be determined.\nExiting."
  exit 1
fi