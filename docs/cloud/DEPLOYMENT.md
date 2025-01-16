# Hosting Sense on the Internet/Intranet

Sense is an application with four application containers, a database 
(PostgreSQL), and a cache (Redis).

You can deploy these containers and dependencies in any way you want. 
Sense supports hosting on AWS, and most likely, Google Cloud Platform and 
Azure as well. As long as the platform can host Docker containers (even 
the database can be a PostgreSQL container, but do find a way to persist the 
data), it is possible to set up Sense on that hosting provider.

As a starting point, here is **one way** to deploy Sense on AWS. (Even
considering only AWS, there are multiple possible ways to deploy Sense.) 
This is how the Transform team hosted Sense.

## Deploying Sense on AWS

**Example Architecture**

![Example Architecture](../diagrams/architecture-sense-example-aws.svg "Example Architecture")

### Step 1: Spin up all resources

**Application Containers**

* Set up the four containers on AWS ECS Fargate. They can be deployed as 
different services on the same ECS cluster.
* Use AWS ECS Service Connect to allow them to talk to each other without 
going through the internet.
* Expose all of them to external traffic using Application Load Balancer and 
Target Groups. *(Why? Users will use Chat, Admins will use Admin, Metabase and 
Langfuse. For communications between containers, use ECS Service Connect so 
those traffic do not go through internet)*

**Database & Cache**

* Set up RDS PostgreSQL for Sense. It is OK to share one database instance 
for all components and create separate databases for different components: 
one for `metabase`, one for `admin`, and one for `langfuse`. Another database 
is required for `chat` if the Chat History feature is enabled.
* Set up Redis using AWS ElastiCache.

**Database Seeding**

* Create the necessary databases inside the RDS instance. Once possible
  strategy is to create a temporary ECS Task, install `psql` and connect to the
  DB. Refer to `db-init.sql` for sample initialization script

### Step 2: Connecting Them All Together

Once the resources are spun up, it's time to connect them all together and 
make them work.

Refer to the following dependencies diagram:

![Sense Dependencies](../diagrams/sense-dependencies.svg "Sense Dependencies")

The containers with no dependencies (as per the diagram) are `metabase` and 
`langfuse`, so set up those first. Connect them to database and set them up.

### Step 2a: Metabase and Langfuse

`metabase` and `langfuse` are straightforward; just make sure they can reach 
their respective databases (should have been set up in Step 1) and you are 
good to go.

### Step 2b: Admin

Next, set up `admin` as it only relies on `metabase`

**Admin --> Metabase**

* You will need an API key for `admin` to work with `metabase`. Create an API
  key under Administrator group and put it into `admin` environment variables

**Database Seeding**

* For `admin`, once the containers are set up, you will need to run DB migrate
  and then seed the first superuser. To run DB migrate, run the `admin`
  container but override the command to `npx prisma migrate deploy`
* After that, add the first superuser. See sample script in
  `sense-admin-init-first-superuser.sql`

**Expected results:** You should be able to access Sense Admin at the end of this step, and go to 
Metabase --> Database and see the list of databases inside Metabase.

### Step 2c: Chat

Finally, set up `chat` as it relies on all of the other three components.

**Chat --> Langfuse**

* Set up Langfuse (you can refer to Langfuse's documentation). You should have 
a project set up
* **API Key:** Create a key-pair under the project you created and put it into 
`chat` environment variables
* **Prompt:** Create a prompt called `metabase-guided-agent-chat`. Context as 
per `prompt.txt`. Save. Promote to production. (Click on the button with flag 
icon, and select "production".)

**Chat --> Metabase**

* You will need an API key for `chat` to work with `metabase`. Create an API
  key under Administrator group and put it into `chat` environment variables. 
If you prefer, you can re-use the API key that `admin` uses

**Expected results:** You should be able to log into Sense, see the database 
that you have granted yourself, ask a question, and get a successful answer 
back.

## Example Terraform code

Example Terraform code is provided. Pluck in your variables and 
`terraform init` and `terraform plan`.