# gcp-examples
A Repo with scripts for GCP


mkdir deploy
cd deploy
git init
git remote add -f origin https://github.com/vansoncrasta/gcp-examples
git config core.sparseCheckout true
git sparse-checkout set  docs terraform

mkdir test4
cd test4
git init
git remote add -f origin https://github.com/vansoncrasta/gke-logging-sinks-demo
git config core.sparseCheckout true
git sparse-checkout set docs test/boilerplate
git pull origin master
