# GKE Public Cluster example
Example to deploy GKE public cluster

```
gcloud config set project PROJECT_ID

gcloud config set compute/region asia-south1
gcloud config set compute/zone asia-south1-c
```

```
mkdir deploy
cd deploy
git init
git remote add -f origin https://github.com/vansoncrasta/gcp-examples
git config core.sparseCheckout true
git sparse-checkout set gcp-examples/gke-public-cluster
git pull origin master
```
