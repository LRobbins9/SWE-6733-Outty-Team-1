# CD/CD Pipeline

## Technology Stack
For the CI/CD pipeline, team 1 chose to utilize GitHub actions and Firebase Hosting [https://firebase.google.com/docs/hosting/github-integration]. Firebase Hosting is able to integrate with GitHub action to build and deploy the code. In the .github/workflows directory there are 2 .yml files that handle the pipeline, one for pull request and one for merging. Both will checkout the repository, set up Flutter, install dependencies, build the web, run all the unit test (if any unit tests fail, the build will immediately stop), and deploy the Outty app to the Firebase Hosting frontend. The main difference between the two is in the pull request a "preview deployment" is built based on that code to be able to see what it looks like, test and fix anything found. In the merging everything will be built again but this time the final version will be pushed to the main deployment website. A breakdown of this structure can be seen below.  

## GitHub Actions Setup 

<img width="1842" height="642" alt="image" src="https://github.com/user-attachments/assets/65eb5876-2604-45a4-b27e-7edf7fae0425" />

## Pull Request Pipeline
(show a sprint 3 build)

## Merging Pipeline 
The production deployment is found here -> https://outty-app-team-1.firebaseapp.com/

<img width="1877" height="692" alt="image" src="https://github.com/user-attachments/assets/006fa051-f002-48de-9677-12b7f4cbbbe7" />


