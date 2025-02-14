# Database Strategy

## Main goals

- How to handle version control
- How to track what is deployed easily
- How to easily take backups
- How to decentralize efficiently for horizontal scalability
- How to keep it all performance-oriented
- Can we generate a data lineage graph
- How to store secrets and manage auto-updates
- How to achieve end-to-end automation for this with DevOps

---

## Version Control

- Methodologies:
  - State-based approach
    - involves defining ideal state of DB
    - requires some automated system to scan and compare changes between ideal and current, and apply the required changes
    - not always consistent
  - Migration-based approach [PREFER-THIS]
    - involves tracking every change to the DB
    - always consistent
- Important considerations:
  - tracking changes
  - how to rollback
  - avoiding or detecting/mitigating drift
- Alternatives:
  - Can follow the TI way of doing it
    - write files with all data
    - add separate folders with files for procedures etc
    - cons
      - cannot easily figure out what is deployed and what is not (especially modifications to Pl/SQL but others too)
        - could try to make non-editable branches for each env which can only be edited by CI/CD user while making sure merge and deploy happen with no delay
      - weird format for file names specifying unique id and which user to run queries in the file as (latter was rather unintuitive)
      - have this weird concept of using `/` and `@@` which aren't standard SQL
      - currently works with a single instance of a vertically scaled machine which is a SPOF (single point of failure)
        - could create separate repositories for each instance
  - Can look at Liquibase (which TI was considering but isn't any longer due to license issues)
  - Some links at https://jirasoulrupture.atlassian.net/wiki/spaces/~557058ba5230b20e9f4beaacdf07e9cbe66191/pages/667811841/Nov+2024#DB-Version-control

---
