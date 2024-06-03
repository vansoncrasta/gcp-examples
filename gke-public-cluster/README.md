# GKE Public Cluster example
Example to deploy GKE public cluster

```
gcloud config set project PROJECT_ID

gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-c

```

```
mkdir deploy
cd deploy
git init
git remote add -f origin https://github.com/vansoncrasta/gcp-examples
git config core.sparseCheckout true
git sparse-checkout set gke-public-cluster
git pull origin main
chmod -R 777 gke-public-cluster
cd gke-public-cluster
```

```
make create
make validate
make teardown
```
