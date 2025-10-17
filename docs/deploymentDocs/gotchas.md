Microsoft.ContainerService needs to be registered

Tag images with branch name
- how to do this
Then whenever you do a deploy for the container app, do a build and push the image

pass the image name as an artifact to the container app deploy step

Generate a tag on the resource group that has api version and the ui version so tags reflect what was deployed