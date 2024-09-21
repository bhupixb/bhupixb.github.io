---
company: "Zeta (DirectI)"
role: "Software Engineer"
dateStart: "7 Jan 2021"
dateEnd: "30 Sept 2024"
---

This is going to be a long one :)

I was just out of college when I first joined Zeta.
I had only used C/C++ for [Competitive Programming](https://www.stopstalk.com/user/profile/bhupixb), no experience with <i>Frontend/Backend/Devops</i>. I wasn't even familiar with <b>git</b>.
During first few weeks of work, my mentor explained me some work and asked me to create a PR for it and share with him.
I googled "PR" and the first result was "Public Relations". I was like what does this guy want? On asking my fellow team mates I got to know he meant "Pull Request, at some places it's referred to as CL. That was the first time, I setup git and learned a bit about it.

I was just out of college when I first joined **Zeta**.

I had only used **C/C++** for [Competitive Programming](https://www.stopstalk.com/user/profile/bhupixb), with no experience in *Frontend*, *Backend*, or *DevOps*. I wasn't even familiar with **Git**.

During the first few weeks of work, my mentor explained some tasks to me and asked me to create a **PR** for it and share it with him.

I googled "PR" and the first result was **Public Relations**. I was like, *What does this guy want?* 😅

Upon asking my fellow teammates, I got to know he meant **Pull Request**. (At some places, it's referred to as **CL**.)

That was the first time I set up Git and learned a bit about it.


tldr: I worked at Zeta for 3 yr 9 months. I worked on a lot of different things in my time there. I started as a DevOps guy, then to data engineering, and finally in the data Platform team as Backend dev.

#### Granfana and Prometheus (Jan 2021 - June 2021)
I initially joined the Data Infra team. 

- Built a Grafana dashboard for RDS monitoring with data source as Prometheus. We were earlier using AWS CloudWatch integration with grafana but I think it was costly from what I remember because we need to call CloudWatch API per user(Dev/SRE etc) opening the Dashboard. So we decided that we will scrape the metrics every 30s/1min from Cloudwatch and store it in our Prometheus.
These metrics were scraped from AWS CloudWatch using [YACE exporter](https://github.com/nerdswords/yet-another-cloudwatch-exporter).
Sample metrics:
```sql
aws_rds_cpuutilization_average{dimension_DBInstanceIdentifier="my-aws-rds", ...}
```

- Alerting with dynamic thresholds using AWS RDS tags.
Implemented a simple Backend service(using Flask and [prometheus client](https://github.com/prometheus/client_python)) which would list all RDS, parse the RDS tags and emit Prometheus metrics for alert thresholds.
This allowed for more flexible and dynamic alerting configurations based on different RDS type.
E.g. an RDS which has critical data can be configured to trigger an alert at a lower threshold than others. It also allowed to write a single alert rule(per metric type) in Prometheus which would trigger alerts based on these dynamic thresholds.
Sample metrics:
```sql
aws_rds_cpuutilization_threshold{dimension_DBInstanceIdentifier="my-aws-rds", ...}
```

#### One stop database solution for devs (July 2021 - Feb 2022)
Data Infra team was ok but I wasn't satisfied as I didn't code a lot and I wrote a lot of helm charts there. I was more interested in Coding. So I tried a new FrontEnd project. I never touched Html/Css before this, not even during my Undergraduate.

In this project, I worked on building an internal website for monitoring and accessing logical databases(Postgres).
It has tools embedded e.g. [pgweb](https://github.com/sosedoff/pgweb) for accessing database, [pgbadger](https://github.com/darold/pgbadger) for analysing slow queries etc.
It gave a single place for all database related tools and monitoring, passwordless login to Database(details omitted).
This was built from empty web page to fully working state with Google auth as login using Vue JS, Typescript, SCSS, Buefy.
**ps**: I have omitted lots of internal workings above for obvious reasons.

It was an interesting experience, I learnt about how FE works, different type of http request methods, REST, using DevTools for debugging, collaborating with BE folks, finalizing API specs etc etc. But I also realized that it's not for me. So I went on to try something new.


#### Data Engineering Flink and Airflow (March 2022 - March 2023)
Then I moved to on to working with Flink and airflow. It was a flink library for very specific usecase for Batch processing.

I mostly worked as an Infra guy, upgrading flink/Airflow to latest version, using Flink K8s operator for deploying flink clusters, grafana dashboards for monitoring, writing helm charts for deploying new flink clusters.

I did not find it very interesting over time as after standardizing the setup, it was mostly about maintaining the setup and not much new learning.


#### Flink as a Service (March 2023 - Sept 2024):
Finally, I convinced my Manager that I want to work on Backend side of things and moves to a new team/project.

In this new team we built **Flink as a Service** for **Record** (a record can be thought of as a Kafka event, a line in a file, or a row in a database, etc.) processing use cases for our entire organization.

This was the first time I worked as a **Backend developer**.

The aim of this new product was solve use cases of **Batch/Stream processing** with a simple YAML specification, NO CODE:
- Data enrichment
- Transformation
- Executing HTTP requests per record
- Data migration from a source to sink (**No Code**)

For complex use cases, users could extend the Java library and write their own custom operators.

We had an internal Java library that would translate these YAML specification to an actual Flink job and execute it.

**Platform Overview:**

This platform consists of:

1. A **Java library** on top of Flink, providing lots of out-of-the-box (OOTB) source/sink connectors, transformations, HTTP operators, etc. It was much more than just a wrapper over Flink, with features like:
    - Custom metrics
    - Exception logging
    - Writing data to Flink's side output for record-level processing stats, etc.

2. The **Control plane**, which accepts the job specification (defined in YAML/JSON) and executes the job. It has many metrics for job monitoring and reconciliation. I wrote most of the control plane in **Java + Spring Boot** for:
    - Managing the end-to-end lifecycle of a Flink job
    - Submitting new jobs
    - Reconciling in-progress jobs
    - Post-processing jobs once they are finished

3. **Self-hosted Flink clusters on K8s**. We self hosted Flink on K8s using Flink Kubernetes Operator. I used to manage it fully.My previous experience as DevOps helped a lot here.

We also used Trino(self hosted) for calculating the record processing stats, provided to our users as an offering for.

**Key Learnings:**

I learned a lot during this project. It was a very different mindset and kind of work when you are building a platform that is directly used by other fellow developers.

- A lot of thinking into designing APIs and specifications so that they are **easy to use** for other developers and **extensible** in the future.
- Writing code that is easy to maintain and easy to extend when required by the library users.
- Testing the library, making different connectors as configurable as possible(different teams had different needs), and writing **good documentation** were crucial parts of the work.

**Product Advocacy:**

Building a product is one thing, but advocating for it, gathering feedback, iterating on it, and making it better is a different thing.

- **Convincing other teams** that why our Platform is best for their use case and migrate from their existing architecture was challenging.
- We had to show how the platform solves their problems, and provides out-of-the-box **monitoring**, **observability**, **scaling**, **maintenance**, etc.

**Testing at scale:**
We did load testing of our platform to prove it's scalability and reliability. Some of the tests we did:

-  A batch job to execute 200 Million HTTP requests(avg 100 ms latency) in 28 minutes with 15 Task Manager pods.
-  Generating and uploading 40 million credit card pdf statements in 5 mins. We had to do a lot of tuning of flink cluster as well as S3 side for testing this scale. 40M file upload is not a big deal, but doing it in 5 min is. We faced [rate limits](https://xebia.com/blog/optimizing-performance-of-amazon-s3/) from S3.


It was the most challenging and interesting project I worked on at Zeta.
