# Storage Bucket
https://cloud.google.com/config-connector/docs/reference/resource-docs/storage/storagebucket

This chart creates a Google Cloud storage bucket with an optional standard policy binding for service accounts.
The annotation `cnrm.cloud.google.com/deletion-policy` is set to abandon by default, so deleting the `StorageBucket` object in Kubernetes will not delete the bucket.
Policy bindings for service accounts will be deleted.

To setup a bucket with default settings and no policy bindings, just change the name for bucket. Remember that the name must be globally unique.

## Example

Below is an example where the storage class is changed to Nearline and a service account is added.
The service account MUST be the name of an `IAMServiceAccount` Kubernetes object in the same namespace as where the storage bucket is going to be deployed.
The service account will get the role on the project as defined, but the policy will be restricted to only this bucket using a condition. You can find the different Cloud Storage Roles [here.](https://cloud.google.com/iam/docs/understanding-roles#cloud-storage-roles)

```yaml
name: my-unique-bucket-name
spec:
  storageClass: NEARLINE

serviceAccounts:
  - name: my-service-account-name
    projectId: my-google-project-id
    role: roles/storage.objectViewer
```

The `spec:` property is templated 1:1 into the `StorageBucket` object, so any configuration from Google Docs are supported. You can find the Spec schema [here.](https://cloud.google.com/config-connector/docs/reference/resource-docs/storage/storagebucket#schema)

## Lifecycle Rules

>To support common use cases like setting a Time to Live (TTL) for objects, retaining noncurrent versions of objects, or "downgrading" storage classes of objects to help manage costs, Cloud Storage offers the Object Lifecycle Management feature.

Setting up Lifecycle rules can be a bit confusing so here's a few exampels.

```yaml
...
spec:
  versioning: true
  lifecycleRule:
    # Will keep 5 versions of an object incl. the live object. 
    # Older versions will be deleted.
    - action:
        type: Delete
      condition:
        numNewerVersions: 5
        withState: ARCHIVED
    # Will delete archived versions of an object that are older
    # than 30 days.
    - action:
        type: Delete
      condition:
        daysSinceNoncurrentTime: 30
```