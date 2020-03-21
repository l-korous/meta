Prerequisites
-------------
- Docker
- MSSQL
- Bash
- Java

How to use
----------

./mgmt/bin/prepare_deployment.sh \<xmlModelPath\> \<targetPath\>

> 1) creates a directory <targetPath> if it does not exist
> 2) according to the \<xmlModelPath\> file, which needs to be in the same structure as files in examples/\*\*/\*.xml, generates in \<targetPath\> a complete deployment of an application - DB scripts creating a repository, a Dockerfile, and all contents for it to host Node.js backend app and for serving static HTML&JS frontend
> 3) you should see a message 'Preparation successful, run deploy.sh in \<targetPath\>'

\<targetPath\>/deploy.sh

> 1) deploys the DB repository in the configured MSSQL DB
> 2) creates a Docker image with the Node.js backend application, and frontend static-serving server running on port 80. The application is available at \<hostname\>/app/\<tableName\>.html

\<targetPath\>/runApp.sh

> Runs the docker container, after stopping all other running containers with this image