#!/bin/bash
set -e

NAME=$1
if [ -z "$NAME" ]; then
  echo "Usage: new-project <project-name>"
  exit 1
fi

gh repo create "peteedoo/$NAME" --public --template=peteedoo/project-template --clone
cd "$NAME"

DATE=$(date +%Y-%m-%d)
sed -i '' "s/{project-name}/$NAME/g" README.md
sed -i '' "s/{date}/$DATE/g" README.md

git add README.md
git commit -m "chore: init project from template"
git push

echo "Created https://github.com/peteedoo/$NAME"
